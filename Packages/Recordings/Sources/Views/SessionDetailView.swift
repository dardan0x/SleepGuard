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
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var viewState: ViewState = .loading

  // MARK: - Legacy Audio Playback (full-session files)
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var currentPlaybackTime: TimeInterval = 0

  // MARK: - Clip Audio Playback (per-event clips)
  @State private var playbackController = ClipPlaybackController()
  @State private var isPlayerExpanded = false
  @State private var waveformSamples: [Float] = []
  @State private var spectrumBars: [Float] = []

  // MARK: - Share
  @State private var isSharePresented = false
  @State private var shareItems: [Any] = []
  @State private var showAllEvents = false

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
      case .loaded(let session):
        loadedBody(session: session)
      case .error:
        errorBody
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
  }

  private func loadedBody(session: SleepSession) -> some View {
    let sortedEvents = session.events?.sorted(by: { $0.timestamp < $1.timestamp }) ?? []
    let isClipSession = sortedEvents.contains(where: { AudioFileURLResolver.resolve($0.audioFileURL) != nil })

    return ScrollView {
      VStack(spacing: 24) {
        SessionDetailHeaderView(session: session)

        SessionDetailTimelineView(session: session)

        SessionDetailEventsView(
          session: session,
          showAllEvents: showAllEvents,
          onToggleShowAll: { showAllEvents.toggle() },
          onPlayEvent: { event in
            if isClipSession {
              playClipEvent(event, in: sortedEvents)
            } else {
              seekToLegacyEvent(event, in: session)
            }
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

        if isClipSession {
          clipPlayerSection(session: session, sortedEvents: sortedEvents)
        } else if session.audioFileURL != nil {
          legacyPlayerSection(session: session)
        }
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
    .task {
      if isClipSession {
        setupClipPlayback(events: sortedEvents)
      } else {
        setupAudioPlayer(for: session)
      }
    }
    .task(id: isPlaying) {
      if !isClipSession {
        await trackLegacyPlaybackProgress()
      }
    }
    .sheet(isPresented: $isSharePresented) {
      ActivityView(activityItems: shareItems)
    }
  }

  // MARK: - Clip Playback Section

  private func clipPlayerSection(session: SleepSession, sortedEvents: [SnoreEvent]) -> some View {
    let markers = clipEventMarkers()
    let colors = eventMarkerColors(events: sortedEvents)
    return VStack(spacing: 12) {
      SessionDetailMiniPlayerView(
        session: session,
        isPlaying: playbackController.isPlaying,
        progress: clipProgress,
        totalDuration: playbackController.totalClipsDuration,
        eventMarkers: markers,
        eventMarkerColors: colors,
        isExpandable: true,
        onTogglePlayback: { playbackController.togglePlayback() },
        onScrub: { relative in playbackController.seek(to: relative) },
        onExpand: { isPlayerExpanded.toggle() }
      )

      if isPlayerExpanded, let currentEvent = currentClipEvent(in: sortedEvents) {
        SessionDetailAdvancedPlayerView(
          event: currentEvent,
          waveformSamples: waveformSamples,
          spectrumBars: spectrumBars,
          onWaveformTap: { relative in
            playbackController.seekInCurrentClip(relative: relative)
          }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  private var clipProgress: Double {
    let total = playbackController.totalClipsDuration
    return total > 0 ? playbackController.currentTime / total : 0
  }

  /// Marker positions (0–1) on the concatenated clips timeline.
  private func clipEventMarkers() -> [Double] {
    let durations = playbackController.events.map { $0.snoreDuration }
    let total = durations.reduce(0, +)
    guard total > 0 else { return [] }
    var accumulated: TimeInterval = 0
    var markers: [Double] = []
    for duration in durations {
      markers.append(accumulated / total)
      accumulated += duration
    }
    return markers
  }

  /// Marker positions (0–1) on the full session timeline for legacy playback.
  private func legacyEventMarkers(session: SleepSession) -> [Double] {
    let total = session.totalDuration
    guard total > 0 else { return [] }
    return (session.events ?? [])
      .sorted { $0.timestamp < $1.timestamp }
      .map { $0.timestamp.timeIntervalSince(session.startDate) / total }
  }

  private func eventMarkerColors(events: [SnoreEvent]) -> [Color] {
    let theme = Theme.shared
    return events.map { theme.intensityColor($0.intensity) }
  }

  private func currentClipEvent(in events: [SnoreEvent]) -> SnoreEvent? {
    let index = playbackController.currentEventIndex
    guard index >= 0, index < events.count else { return nil }
    return events[index]
  }

  private func setupClipPlayback(events: [SnoreEvent]) {
    playbackController.loadEvents(events)
    loadVisualization(for: events.first)
  }

  private func playClipEvent(_ event: SnoreEvent, in events: [SnoreEvent]) {
    guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
    playbackController.playEvent(at: index)
    loadVisualization(for: event)
  }

  private func loadVisualization(for event: SnoreEvent?) {
    guard let event, let url = AudioFileURLResolver.resolve(event.audioFileURL) else {
      waveformSamples = []
      spectrumBars = []
      return
    }
    Task {
      let samples = WaveformGenerator.generateSamples(from: url)
      let bars = WaveformGenerator.spectrumSamples(from: url)
      await MainActor.run {
        waveformSamples = samples
        spectrumBars = bars
      }
    }
  }

  // MARK: - Legacy Playback Section

  private func legacyPlayerSection(session: SleepSession) -> some View {
    let markers = legacyEventMarkers(session: session)
    let colors = eventMarkerColors(events: (session.events ?? []).sorted { $0.timestamp < $1.timestamp })
    return SessionDetailMiniPlayerView(
      session: session,
      isPlaying: isPlaying,
      progress: audioProgress,
      totalDuration: audioPlayer?.duration ?? session.totalDuration,
      eventMarkers: markers,
      eventMarkerColors: colors,
      isExpandable: false,
      onTogglePlayback: toggleLegacyPlayback,
      onScrub: { relative in scrubLegacyTo(relative: relative) },
      onExpand: {}
    )
  }

  private var audioProgress: Double {
    let total = audioPlayer?.duration ?? 0
    return total > 0 ? currentPlaybackTime / total : 0
  }

  private func setupAudioPlayer(for session: SleepSession) {
    guard let url = AudioFileURLResolver.resolve(session.audioFileURL) else { return }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      audioPlayer = player
    } catch {
      // Audio playback is optional; fail silently
    }
  }

  private func trackLegacyPlaybackProgress() async {
    guard isPlaying else { return }
    while !Task.isCancelled {
      try? await Task.sleep(for: .milliseconds(100))
      if let player = audioPlayer {
        currentPlaybackTime = player.currentTime
        if !player.isPlaying {
          isPlaying = false
        }
      }
    }
  }

  private func toggleLegacyPlayback() {
    guard let player = audioPlayer else { return }
    if player.isPlaying {
      player.pause()
      isPlaying = false
    } else {
      do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        // Continue anyway; playback may still work
      }
      player.play()
      isPlaying = true
    }
  }

  private func seekToLegacyEvent(_ event: SnoreEvent, in session: SleepSession) {
    guard let player = audioPlayer else { return }
    let eventTime = event.timestamp.timeIntervalSince(session.startDate)
    player.currentTime = max(0, min(eventTime, player.duration))
    if !player.isPlaying {
      player.play()
      isPlaying = true
    }
  }

  private func scrubLegacyTo(relative: Double) {
    guard let player = audioPlayer else { return }
    let time = relative * player.duration
    player.currentTime = max(0, min(time, player.duration))
    currentPlaybackTime = player.currentTime
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
        diagnoseAudioFiles(for: session)
        viewState = .loaded(session: session)
      } else {
        viewState = .error
      }
    } catch {
      viewState = .error
    }
  }

  private func diagnoseAudioFiles(for session: SleepSession) {
    let eventCount = session.events?.count ?? 0
    let clipsFound = session.events?.filter {
      AudioFileURLResolver.resolve($0.audioFileURL) != nil
    }.count ?? 0
    let legacyURL = AudioFileURLResolver.resolve(session.audioFileURL)
    print("[SessionDetailView] Session \(session.id.uuidString.prefix(8)) — Events: \(eventCount), Clips found: \(clipsFound), Legacy audio: \(legacyURL != nil)")
    if let events = session.events {
      for event in events {
        let exists = AudioFileURLResolver.resolve(event.audioFileURL) != nil
        print("[SessionDetailView]   Event \(event.id.uuidString.prefix(8)) — file: \(event.audioFileURL ?? "nil") — exists: \(exists)")
      }
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
        deleteSessionFiles(session)
        modelContext.delete(session)
        try modelContext.save()
        dismiss()
      }
    } catch {
      // Deletion failed; fail silently
    }
  }

  private enum ViewState {
    case loading
    case loaded(session: SleepSession)
    case error
  }
}
