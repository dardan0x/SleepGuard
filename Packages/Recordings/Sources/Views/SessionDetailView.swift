import SwiftUI
import SwiftData
import AVFoundation
import AudioEngine
import Models
import Env
import DesignSystem

@MainActor
public struct SessionDetailView: View {
  let sessionID: UUID

  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var viewState: ViewState = .loading
  @State private var activeSheet: DetailSheet?
  @State private var selectedFilter: EventCategoryFilter = .all

  // MARK: - Share
  @State private var isGeneratingPDF = false
  @State private var isExportingEvent = false

  public init(sessionID: UUID) {
    self.sessionID = sessionID
  }

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        Color.clear
          .task {
            await loadSession()
          }
      case .loaded(let session, _, let isClipSession):
        loadedBody(session: session, isClipSession: isClipSession)
      case .error:
        errorBody
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
  }

  private func loadedBody(session: SleepSession, isClipSession: Bool) -> some View {
    ScrollView {
      VStack(spacing: 24) {
        SessionDetailHeaderView(session: session, score: session.sleepScore)

        SessionDetailTimelineView(session: session)

        MelodyGapsBannerView(session: session)

        LowBatteryBannerView(session: session)

        if shouldShowFilter {
          Picker("", selection: $selectedFilter) {
            ForEach(EventCategoryFilter.allCases, id: \.self) { filter in
              Text(filter.displayName).tag(filter)
            }
          }
          .pickerStyle(.segmented)
        }

        SessionDetailEventsView(
          events: filteredEvents,
          displayDurations: displayDurations,
          title: eventsTitle,
          onShowAll: { activeSheet = .events },
          onPlayEvent: { event in
            activeSheet = .player(initialEvent: event)
          },
          onShareEvent: { event in
            if isClipSession, let url = AudioFileURLResolver.resolve(event.audioFileURL) {
              shareEventClip(url: url)
            } else {
              Task {
                await exportAndShare(event: event, in: session)
              }
            }
          }
        )

        if !shortEvents.isEmpty {
          Button {
            activeSheet = .shortEventsPlayer
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
              Text(String(format: Strings.sessionDetailHiddenEventsFormat, shortEvents.count))
                .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.accent.opacity(0.12))
            .cornerRadius(theme.radiusCard)
          }
        }
//          //TODO: Add mini player if we want in future
//          if isClipSession || session.audioFileURL != nil {
//              fakePlayerSection(session: session, sortedEvents: sortedEvents, isClipSession: isClipSession)
//          }
      }
      .padding(20)
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(navigationTitle(for: session.startDate))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 16) {
          Button {
            exportReport(session: session)
          } label: {
            Image(systemName: isGeneratingPDF ? "clock" : "doc.text")
              .font(.system(size: 17))
              .foregroundStyle(isGeneratingPDF ? theme.textTertiary : theme.accent)
          }
          .disabled(isGeneratingPDF)
          if !isClipSession, session.audioFileURL != nil {
            Button {
              shareFullSession(session: session)
            } label: {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17))
                .foregroundStyle(theme.accent)
            }
          }
          Button {
            deleteSession()
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 17))
              .foregroundStyle(theme.destructive)
          }
        }
      }
    }
    .sheet(item: $activeSheet) { sheet in
      switch sheet {
      case .player(let initialEvent):
        let episodeEvents = initialEvent.map { session.episodePlaybackEvents(for: $0) } ?? filteredEvents
        PlayerSheetView(
          session: session,
          sortedEvents: episodeEvents,
          isClipSession: isClipSession,
          initialEvent: episodeEvents.first ?? initialEvent
        )
      case .events:
        EventsSheetView(
          session: session,
          events: filteredEvents,
          displayDurations: displayDurations,
          isClipSession: isClipSession,
          onPlayEvent: { _ in }
        )
      case .shortEventsPlayer:
        PlayerSheetView(
          session: session,
          sortedEvents: shortEvents,
          isClipSession: isClipSession,
          initialEvent: nil
        )
      }
    }

    .overlay {
      if isExportingEvent {
        ZStack {
          theme.bgPrimary.opacity(0.7)
            .ignoresSafeArea()
          ProgressView()
            .scaleEffect(1.5)
            .tint(theme.accent)
        }
      }
    }
  }

  // MARK: - Fake Player Placeholder

  private func fakePlayerSection(session: SleepSession, sortedEvents: [SnoreEvent], isClipSession: Bool) -> some View {
    let totalDuration: TimeInterval = isClipSession
      ? sortedEvents.map { $0.snoreDuration }.reduce(0, +)
      : session.totalDuration
    let markers = isClipSession
      ? clipEventMarkers(events: sortedEvents, totalDuration: totalDuration)
      : legacyEventMarkers(session: session, sortedEvents: sortedEvents)
    let colors = eventMarkerColors(events: sortedEvents)

    return VStack(alignment: .leading, spacing: 8) {
      Text(Strings.recordingsDetailTimelineLabel)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      SessionDetailMiniPlayerView(
        session: session,
        isPlaying: false,
        progress: 0,
        totalDuration: totalDuration,
        eventMarkers: markers,
        eventMarkerColors: colors,
        isExpandable: false,
        showsPlaybackButton: false,
        onTogglePlayback: {},
        onScrub: { _ in },
        onExpand: {}
      )
    }
  }

  private func clipEventMarkers(events: [SnoreEvent], totalDuration: TimeInterval) -> [Double] {
    guard totalDuration > 0 else { return [] }
    var accumulated: TimeInterval = 0
    var markers: [Double] = []
    for event in events {
      markers.append(accumulated / totalDuration)
      accumulated += event.snoreDuration
    }
    return markers
  }

  private func legacyEventMarkers(session: SleepSession, sortedEvents: [SnoreEvent]) -> [Double] {
    let total = session.totalDuration
    guard total > 0 else { return [] }
    return sortedEvents.map { $0.timestamp.timeIntervalSince(session.startDate) / total }
  }

  private func eventMarkerColors(events: [SnoreEvent]) -> [Color] {
    events.map { theme.intensityColor($0.intensity) }
  }

  // MARK: - Share

  private func shareEventClip(url: URL) {
    guard FileManager.default.fileExists(atPath: url.path) else { return }
    presentShareSheet(items: [url])
  }

  private func exportAndShare(event: SnoreEvent, in session: SleepSession) async {
    guard let sourceURL = AudioFileURLResolver.resolve(session.audioFileURL) else { return }

    isExportingEvent = true
    defer { isExportingEvent = false }

    let asset = AVURLAsset(url: sourceURL)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }

    let eventTime = event.timestamp.timeIntervalSince(session.startDate)
    let startTime = max(0, eventTime)
    let endTime = min(asset.duration.seconds, eventTime + event.snoreDuration)
    guard endTime > startTime else { return }

    exportSession.timeRange = CMTimeRange(
      start: CMTime(seconds: startTime, preferredTimescale: 600),
      duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
    )

    let tempDir = FileManager.default.temporaryDirectory
    let clipURL = tempDir.appendingPathComponent("snore_event_\(event.id.uuidString).m4a")
    if FileManager.default.fileExists(atPath: clipURL.path) {
      try? FileManager.default.removeItem(at: clipURL)
    }
    exportSession.outputURL = clipURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    guard exportSession.status == .completed else { return }

    // Verify the exported file exists and has content before presenting
    guard FileManager.default.fileExists(atPath: clipURL.path),
          let attrs = try? FileManager.default.attributesOfItem(atPath: clipURL.path),
          let fileSize = attrs[.size] as? Int, fileSize > 0 else { return }

    presentShareSheet(items: [clipURL])
  }

  // MARK: - Data & Actions

  private var errorBody: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsErrorMessage)
        .font(.headline)
        .foregroundStyle(theme.textPrimary)
    }
  }

  private func loadSession() async {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        let stagesEmptyAndOld = (session.sleepStageSegments?.isEmpty == true)
          && (session.endDate?.timeIntervalSinceNow ?? 0) < -3600
        if userPreferences.enhancedSleepTracking && (session.sleepStageSegments == nil || stagesEmptyAndOld) {
          let stages = await HealthKitSync.shared.fetchSleepStages(for: session)
          session.sleepStageSegments = stages.isEmpty ? [] : stages
        }

        // Recalculate cached score and snoring duration to pick up scoring
        // formula changes (e.g. episode merging, gap inclusion) while the
        // session relationship is hot.
        session.hasCachedScore = false
        session.cachedSleepScore = session.sleepScore
        session.cachedSnoringDuration = session.snoringDuration
        session.hasCachedScore = true
        try modelContext.save()

        let sortedEvents = session.events?.sorted(by: { $0.timestamp < $1.timestamp }) ?? []
        let isClipSession = sortedEvents.contains(where: { AudioFileURLResolver.resolve($0.audioFileURL) != nil })
        viewState = .loaded(session: session, sortedEvents: sortedEvents, isClipSession: isClipSession)
      } else {
        viewState = .error
      }
    } catch {
      viewState = .error
    }
  }

  private func navigationTitle(for date: Date) -> String {
    DateFormatters.dayOfWeekAndDate.string(from: date)
  }

  private func exportReport(session: SleepSession) {
    Task {
      isGeneratingPDF = true
      defer { isGeneratingPDF = false }
      if let url = SleepReportPDFGenerator().generatePDF(for: session) {
        presentShareSheet(items: [url])
      }
    }
  }

  private func shareFullSession(session: SleepSession) {
    guard let url = AudioFileURLResolver.resolve(session.audioFileURL) else { return }
    presentShareSheet(items: [url])
  }

  private func presentShareSheet(items: [Any]) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.keyWindow?.rootViewController else { return }
    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
    rootVC.present(activityVC, animated: true)
  }

  private func deleteSession() {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        // Delete events first with intermediate save to avoid SwiftData
        // faulting crash during cascade delete.
        if let events = session.events {
          for event in events {
            modelContext.delete(event)
          }
          try modelContext.save()
        }

        // Resolve transformable faults before deletion
        _ = session.sleepStageSegments
        _ = session.recordingGaps
        deleteSessionFiles(session)
        modelContext.delete(session)
        try modelContext.save()
        dismiss()
      }
    } catch {
      // Deletion failed; fail silently
    }
  }

  private var shouldShowFilter: Bool {
    guard case .loaded(_, let sortedEvents, _) = viewState else { return false }
    return Set(sortedEvents.map(\.category)).count > 1
  }

  /// Display duration overrides for episode representatives.
  /// Uses the episode's full snoring span so melody gaps where snoring
  /// resumed are included, matching the stat calculation.
  private var displayDurations: [UUID: TimeInterval] {
    guard case .loaded(let session, _, _) = viewState else { return [:] }
    var map: [UUID: TimeInterval] = [:]
    for episode in session.displayableSnoringEpisodes {
      if let rep = episode.representativeEvent {
        map[rep.id] = episode.snoreDuration
      }
    }
    return map
  }

  /// Short snoring episodes (under 3 sec) shown in the dedicated player.
  private var shortEvents: [SnoreEvent] {
    guard case .loaded(let session, _, _) = viewState else { return [] }
    let shortEpisodes = session.snoringEpisodes.filter { $0.snoreDuration < 3 }
    return shortEpisodes.compactMap(\.representativeEvent)
      .sorted(by: { $0.timestamp < $1.timestamp })
  }

  /// Events for display: displayable snoring episodes + non-snoring events.
  private var filteredEvents: [SnoreEvent] {
    guard case .loaded(let session, let sortedEvents, _) = viewState else { return [] }

    switch selectedFilter {
    case .snoring:
      return session.displayableSnoringEpisodes.compactMap(\.representativeEvent)
    case .sleepTalking, .noise:
      return sortedEvents.filter { selectedFilter.includes(event: $0) }
    case .all:
      let reps = session.displayableSnoringEpisodes.compactMap(\.representativeEvent)
      let others = sortedEvents.filter { $0.category != .snoring }
      return (reps + others).sorted(by: { $0.timestamp < $1.timestamp })
    }
  }

  private var eventsTitle: String {
    switch selectedFilter {
    case .all: return Strings.sessionRecordingEventsFormatAll
    case .snoring: return Strings.sessionRecordingEventsFormatSnoring
    case .sleepTalking: return Strings.sessionRecordingEventsFormatSleepTalking
    case .noise: return Strings.sessionRecordingEventsFormatNoise
    }
  }

  private enum EventCategoryFilter: String, CaseIterable {
    case all
    case snoring
    case sleepTalking
    case noise

    var displayName: String {
      switch self {
      case .all: return Strings.filterAll
      case .snoring: return Strings.filterSnoring
      case .sleepTalking: return Strings.filterSleepTalking
      case .noise: return Strings.filterNoise
      }
    }

    func includes(event: SnoreEvent) -> Bool {
      switch self {
      case .all: return true
      case .snoring: return event.category == .snoring
      case .sleepTalking: return event.category == .sleepTalking
      case .noise: return event.category == .noise || event.category == .coughing || event.category == .other
      }
    }
  }

  private enum ViewState {
    case loading
    case loaded(session: SleepSession, sortedEvents: [SnoreEvent], isClipSession: Bool)
    case error
  }

  private enum DetailSheet: Identifiable {
    case player(initialEvent: SnoreEvent?)
    case events
    case shortEventsPlayer

    var id: String {
      switch self {
      case .player(let event):
        return event.map { "player-\($0.id.uuidString)" } ?? "player"
      case .events:
        return "events"
      case .shortEventsPlayer:
        return "short-events-player"
      }
    }
  }
}
