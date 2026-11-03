import SwiftUI
import AVFoundation
import AudioEngine
import Models
import Env
import DesignSystem

/// Plays individual snore-event audio clips presented as a bottom sheet.
/// Always opens in expanded mode — shows the full event player with waveform and controls.
@MainActor
public struct PlayerSheetView: View {
  let session: SleepSession
  let sortedEvents: [SnoreEvent]
  let isClipSession: Bool
  let initialEvent: SnoreEvent?

  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  // MARK: - Clip Playback
  @State private var playbackController = ClipPlaybackController()
  @State private var waveformSamples: [Float] = []

  // MARK: - Legacy Single-Event Playback
  @State private var legacyPlayer: AVAudioPlayer?
  @State private var legacyIsPlaying = false
  @State private var legacyCurrentTime: TimeInterval = 0
  @State private var legacyEventDuration: TimeInterval = 0

  // MARK: - Loading
  @State private var isReady = false
  @State private var isLoadingWaveform = false
  /// Becomes true once the initial `.task` finishes (or the safety timeout
  /// fires). While false and there's no playable audio yet, the body shows
  /// the loading skeleton instead of the "Audio unavailable" view. This
  /// removes the brief flash users saw on launch where `noAudioView` rendered
  /// for one frame before the player was set up.
  @State private var didFinishInitialLoad = false
  /// Safety net: if loading is still pending after 10 s, fall through to
  /// `noAudioView` so users aren't stuck on the skeleton forever.
  @State private var hasLoadingTimedOut = false

  /// Resolves the session's full audio source, preferring the legacy file and
  /// falling back to the raw archive (used after clip extraction moves it).
  private var playerNavigationTitle: String {
    let event = playbackController.currentEvent ?? initialEvent
    guard let event else { return Strings.eventPlayerNavigationTitle }
    switch event.category {
    case .snoring:
      return Strings.eventPlayerNavigationTitle
    case .sleepTalking:
      return Strings.eventPlayerSleepTalkingTitle
    case .noise, .coughing, .other:
      return Strings.eventPlayerNoiseTitle
    }
  }

  private var sessionAudioURL: URL? {
    AudioFileURLResolver.resolve(session.audioFileURL)
      ?? AudioFileURLResolver.resolve(session.rawAudioFileURL)
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          if isClipSession,
             let currentEvent = playbackController.currentEvent,
             playbackController.hasAudioForCurrentEvent {
            EventPlayerView(
              event: currentEvent,
              waveformSamples: waveformSamples,
              isPlaying: playbackController.isPlaying,
              currentTime: playbackController.currentTime,
              totalDuration: playbackController.totalClipsDuration,
              eventNumber: playbackController.currentEventNumber,
              totalEvents: playbackController.totalEventCount,
              onTogglePlayback: { playbackController.togglePlayback() },
              onSkipBack: { skipClipPlayback(by: -15) },
              onSkipForward: { skipClipPlayback(by: 15) },
              onScrub: { relative in playbackController.seek(to: relative) },
              isReady: isReady,
              isLoadingWaveform: isLoadingWaveform
            )
            enhancedAudioToggle
            if sortedEvents.count > 1 {
              eventListSection
            }
          } else if !isClipSession, let initialEvent, legacyEventDuration > 0 {
            EventPlayerView(
              event: initialEvent,
              waveformSamples: waveformSamples,
              isPlaying: legacyIsPlaying,
              currentTime: legacyCurrentTime,
              totalDuration: legacyEventDuration,
              eventNumber: 1,
              totalEvents: 1,
              onTogglePlayback: toggleLegacyPlayback,
              onSkipBack: { skipLegacyPlayback(by: -15) },
              onSkipForward: { skipLegacyPlayback(by: 15) },
              onScrub: { relative in scrubLegacyTo(relative: relative) },
              isReady: isReady,
              isLoadingWaveform: isLoadingWaveform
            )
          } else if didFinishInitialLoad || hasLoadingTimedOut {
            // Loading is over (either completed or hit the 10 s safety net)
            // and we still don't have audio — show the unavailable state.
            if let event = playbackController.currentEvent ?? initialEvent {
              noAudioView(event: event)
            }
          } else {
            // Initial load still in progress — show skeleton to avoid the
            // "Audio unavailable" flash users were seeing.
            loadingSkeleton
          }
        }
        .padding(20)
      }
      .background(theme.bgPrimary.ignoresSafeArea())
      // Was `.height(470)` — bumped so the Enhanced Audio toggle below the
      // player controls is visible without scrolling. `.large` is also offered
      // so users can drag up for more breathing room if they want.
      .presentationDetents([.height(580), .large])
      .presentationDragIndicator(.visible)
      .navigationTitle(playerNavigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(theme.textTertiary)
          }
        }
      }
    }
    .task {
      // Start loading with max 3-second safety timeout
      let loadingTask = Task {
        try? await Task.sleep(for: .seconds(3))
        if !Task.isCancelled {
          await MainActor.run { isReady = true }
        }
      }

      // Skeleton timeout: after 10 s of no playable audio, fall through to
      // `noAudioView`. The async legacy export normally completes in under
      // a few seconds; this is purely a safety net so the skeleton can't be
      // stuck forever if export fails silently.
      let skeletonTimeoutTask = Task {
        try? await Task.sleep(for: .seconds(10))
        if !Task.isCancelled {
          await MainActor.run { hasLoadingTimedOut = true }
        }
      }

      // Initialize the enhancement toggle from the persisted user preference
      // BEFORE loading the first clip — `setupPlayerForCurrentEvent` reads
      // `enhancedAudioEnabled` to compute per-clip normalization gain.
      playbackController.enhancedAudioEnabled = UserPreferences.shared.enhancedAudioPlayback

      if isClipSession {
        playbackController.loadEvents(sortedEvents)
        if let initialEvent,
           let index = sortedEvents.firstIndex(where: { $0.id == initialEvent.id }) {
          loadVisualization(for: initialEvent)
          if playbackController.hasAudioForCurrentEvent {
            playbackController.playEvent(at: index)
          }
        } else if let firstEvent = sortedEvents.first {
          loadVisualization(for: firstEvent)
          if playbackController.hasAudioForCurrentEvent {
            playbackController.playEvent(at: 0)
          }
        }
      } else if let initialEvent {
        await setupLegacySingleEvent(event: initialEvent)
        loadVisualization(for: initialEvent)
      }

      loadingTask.cancel()
      skeletonTimeoutTask.cancel()
      isReady = true
      didFinishInitialLoad = true
    }
    .task(id: legacyIsPlaying) {
      if !isClipSession {
        await trackLegacyPlaybackProgress()
      }
    }
    .onDisappear {
      playbackController.cleanup()
      legacyPlayer?.stop()
    }
  }

  // MARK: - Event List

  private var eventListSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.recordingsDetailEventsLabel)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      VStack(spacing: 6) {
        ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
          playerEventRow(event: event, index: index)
        }
      }
    }
  }

  private func playerEventRow(event: SnoreEvent, index: Int) -> some View {
    let isActive = playbackController.currentEventIndex == index && isClipSession
    let endTime = event.timestamp.addingTimeInterval(event.snoreDuration)

    return HStack(spacing: 12) {
      categoryIndicator(for: event)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(eventTimeString(event.timestamp))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? theme.accent : theme.textPrimary)

          Text("–")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)

          Text(eventTimeString(endTime))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? theme.accent : theme.textPrimary)
        }

        Text("\(Int(event.snoreDuration))s · \(event.intensity.rawValue.capitalized)")
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
      }

      Spacer()

      if isActive && playbackController.isPlaying {
        Image(systemName: "waveform")
          .font(.system(size: 14))
          .foregroundStyle(theme.accent)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(isActive ? theme.accent.opacity(0.10) : theme.bgCard)
    .cornerRadius(theme.radiusCard)
    .contentShape(Rectangle())
    .onTapGesture {
      if isClipSession {
        playbackController.playEvent(at: index)
        loadVisualization(for: event)
      }
    }
  }

  @ViewBuilder
  private func categoryIndicator(for event: SnoreEvent) -> some View {
    switch event.category {
    case .snoring:
      Circle()
        .fill(theme.intensityColor(event.intensity))
        .frame(width: 8, height: 8)
    case .sleepTalking:
      Image(systemName: "bubble.left.fill")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(theme.sleepTalkingColor)
        .frame(width: 10, height: 10)
    case .noise, .coughing, .other:
      Image(systemName: "waveform")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(theme.noiseColor)
        .frame(width: 10, height: 10)
    }
  }

  private func eventTimeString(_ date: Date) -> String {
    DateFormatters.timeWithPeriod.string(from: date)
  }

  // MARK: - Visualization

  private func loadVisualization(for event: SnoreEvent?) {
    guard let event else {
      waveformSamples = []
      isLoadingWaveform = false
      return
    }
    // Try event clip URL first (run off-main so large files don't block UI)
    if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
      isLoadingWaveform = true
      let duration = event.snoreDuration
      Task.detached(priority: .userInitiated) {
        let samples = WaveformGenerator.generateSamples(from: url, maxDuration: duration)
        await MainActor.run {
          waveformSamples = samples
          isLoadingWaveform = false
        }
      }
      return
    }
    // Fallback: generate from full session audio if available
    guard let sourceURL = sessionAudioURL else {
      waveformSamples = []
      isLoadingWaveform = false
      return
    }
    isLoadingWaveform = true
    Task(priority: .userInitiated) {
      let samples = await generateWaveformFromSession(sourceURL: sourceURL, event: event)
      await MainActor.run {
        waveformSamples = samples
        isLoadingWaveform = false
      }
    }
  }

  private func generateWaveformFromSession(sourceURL: URL, event: SnoreEvent) async -> [Float] {
    // Export a temporary clip and generate waveform from it
    let asset = AVURLAsset(url: sourceURL)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      return []
    }

    let eventTime = event.timestamp.timeIntervalSince(session.startDate)
    let startTime = max(0, eventTime)
    let endTime = min(asset.duration.seconds, eventTime + event.snoreDuration)
    guard endTime > startTime else { return [] }

    exportSession.timeRange = CMTimeRange(
      start: CMTime(seconds: startTime, preferredTimescale: 600),
      duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
    )

    let tempDir = FileManager.default.temporaryDirectory
    let clipURL = tempDir.appendingPathComponent("waveform_\(event.id.uuidString).m4a")
    if FileManager.default.fileExists(atPath: clipURL.path) {
      try? FileManager.default.removeItem(at: clipURL)
    }
    exportSession.outputURL = clipURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    guard exportSession.status == .completed else { return [] }

    return WaveformGenerator.generateSamples(from: clipURL)
  }

  // MARK: - Loading Skeleton

  /// Placeholder shown while the player is being set up (clip controller or
  /// legacy async export). Mimics the rough shape of `EventPlayerView` so the
  /// sheet layout doesn't jump when it transitions to the real player.
  /// A circular `ProgressView` makes it clear something is in progress.
  private var loadingSkeleton: some View {
    VStack(spacing: 20) {
      // Waveform placeholder
      RoundedRectangle(cornerRadius: theme.radiusSmall)
        .fill(theme.bgElevated)
        .frame(height: 80)

      // Scrubber + time placeholders
      VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 2)
          .fill(theme.bgElevated)
          .frame(height: 4)
        HStack {
          Text("0:00")
            .font(.system(size: 12, weight: .medium))
          Spacer()
          Text("0:00")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(theme.textTertiary)
      }

      // Transport controls placeholder
      HStack(spacing: 28) {
        Circle().fill(theme.bgElevated).frame(width: 44, height: 44)
        Circle().fill(theme.bgElevated).frame(width: 64, height: 64)
        Circle().fill(theme.bgElevated).frame(width: 44, height: 44)
      }
      .padding(.top, 4)

      ProgressView()
        .progressViewStyle(.circular)
        .tint(theme.accent)
        .padding(.top, 4)
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  // MARK: - Enhanced Audio Toggle

  /// Toggle for band-pass + per-clip peak normalization on the event player.
  /// Persisted via `UserPreferences.enhancedAudioPlayback` so the choice
  /// survives across sessions.
  private var enhancedAudioToggle: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(Strings.eventPlayerEnhancedAudioLabel)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textPrimary)
        Text(Strings.eventPlayerEnhancedAudioDescription)
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
      }
      Spacer(minLength: 0)
      Toggle("", isOn: Binding(
        get: { playbackController.enhancedAudioEnabled },
        set: { newValue in
          playbackController.enhancedAudioEnabled = newValue
          UserPreferences.shared.enhancedAudioPlayback = newValue
        }
      ))
      .labelsHidden()
      .tint(theme.accent)
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  // MARK: - No Audio State

  private func noAudioView(event: SnoreEvent) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 44))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.eventPlayerNoAudioTitle)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text(Strings.eventPlayerNoAudioDescription)
        .font(.system(size: 14))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 8) {
        Text(event.timestamp, style: .time)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textTertiary)
        Text("·")
          .foregroundStyle(theme.textTertiary)
        Text("\(Int(event.snoreDuration))s · \(event.intensity.rawValue.capitalized)")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  // MARK: - Clip Playback Helpers

  private func skipClipPlayback(by seconds: TimeInterval) {
    let newTime = max(0, playbackController.currentTime + seconds)
    guard playbackController.totalClipsDuration > 0 else { return }
    let relative = newTime / playbackController.totalClipsDuration
    playbackController.seek(to: relative)
  }

  // MARK: - Legacy Single-Event Playback

  private func setupLegacySingleEvent(event: SnoreEvent) async {
    guard let sourceURL = sessionAudioURL else { return }

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
    let clipURL = tempDir.appendingPathComponent("snore_player_\(event.id.uuidString).m4a")
    if FileManager.default.fileExists(atPath: clipURL.path) {
      try? FileManager.default.removeItem(at: clipURL)
    }
    exportSession.outputURL = clipURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    guard exportSession.status == .completed else { return }

    do {
      let player = try AVAudioPlayer(contentsOf: clipURL)
      player.prepareToPlay()
      legacyPlayer = player
      legacyEventDuration = player.duration
      legacyCurrentTime = 0

      let session = AVAudioSession.sharedInstance()
      try? session.setActive(false)
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
      player.play()
      legacyIsPlaying = true
    } catch {
      legacyPlayer = nil
    }
  }

  private func trackLegacyPlaybackProgress() async {
    guard legacyIsPlaying else { return }
    while !Task.isCancelled {
      try? await Task.sleep(for: .milliseconds(100))
      if let player = legacyPlayer {
        legacyCurrentTime = player.currentTime
        if !player.isPlaying {
          legacyIsPlaying = false
        }
      }
    }
  }

  private func toggleLegacyPlayback() {
    guard let player = legacyPlayer else { return }
    if player.isPlaying {
      player.pause()
      legacyIsPlaying = false
    } else {
      do {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false)
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
      } catch {
        // Continue anyway
      }
      player.play()
      legacyIsPlaying = true
    }
  }

  private func skipLegacyPlayback(by seconds: TimeInterval) {
    guard let player = legacyPlayer else { return }
    let newTime = max(0, min(player.currentTime + seconds, player.duration))
    player.currentTime = newTime
    legacyCurrentTime = newTime
  }

  private func scrubLegacyTo(relative: Double) {
    guard let player = legacyPlayer else { return }
    let time = relative * player.duration
    player.currentTime = max(0, min(time, player.duration))
    legacyCurrentTime = player.currentTime
  }
}
