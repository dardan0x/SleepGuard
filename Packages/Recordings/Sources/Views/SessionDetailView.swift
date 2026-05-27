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
  @State private var isSharePresented = false
  @State private var shareItems: [Any] = []

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
            Image(systemName: "doc.text")
              .font(.system(size: 17))
              .foregroundStyle(theme.accent)
          }
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
        PlayerSheetView(
          session: session,
          sortedEvents: initialEvent.map { [$0] } ?? filteredEvents,
          isClipSession: isClipSession,
          initialEvent: initialEvent
        )
      case .events:
        EventsSheetView(
          session: session,
          events: filteredEvents,
          isClipSession: isClipSession,
          onPlayEvent: { _ in }
        )
      }
    }
    .sheet(isPresented: $isSharePresented) {
      ActivityView(activityItems: shareItems)
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
    shareItems = [url]
    isSharePresented = true
  }

  private func exportAndShare(event: SnoreEvent, in session: SleepSession) async {
    guard let sourceURL = AudioFileURLResolver.resolve(session.audioFileURL) else { return }

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

    shareItems = [clipURL]
    isSharePresented = true
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
        if userPreferences.enhancedSleepTracking && session.sleepStageSegments == nil {
          let stages = await HealthKitSync.shared.fetchSleepStages(for: session)
          session.sleepStageSegments = stages.isEmpty ? [] : stages
          try modelContext.save()
        }

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
      if let url = SleepReportPDFGenerator().generatePDF(for: session) {
        shareItems = [url]
        isSharePresented = true
      }
    }
  }

  private func shareFullSession(session: SleepSession) {
    guard let url = AudioFileURLResolver.resolve(session.audioFileURL) else { return }
    shareItems = [url]
    isSharePresented = true
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

  private var filteredEvents: [SnoreEvent] {
    guard case .loaded(_, let sortedEvents, _) = viewState else { return [] }
    return sortedEvents.filter { selectedFilter.includes(event: $0) }
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

    var id: String {
      switch self {
      case .player(let event):
        return event.map { "player-\($0.id.uuidString)" } ?? "player"
      case .events:
        return "events"
      }
    }
  }
}
