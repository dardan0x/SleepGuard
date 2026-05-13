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

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          if isClipSession, let currentEvent = playbackController.currentEvent {
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
              isReady: isReady
            )
          } else if let initialEvent, legacyEventDuration > 0 {
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
              isReady: isReady
            )
          }
        }
        .padding(20)
      }
      .background(theme.bgSecondary.ignoresSafeArea())
      .presentationDetents([.height(420)])
      .presentationDragIndicator(.visible)
      .navigationTitle("Event Player")
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

      if isClipSession {
        playbackController.loadEvents(sortedEvents)
        if let initialEvent,
           let index = sortedEvents.firstIndex(where: { $0.id == initialEvent.id }) {
          playbackController.playEvent(at: index)
          loadVisualization(for: initialEvent)
        } else if let firstEvent = sortedEvents.first {
          playbackController.playEvent(at: 0)
          loadVisualization(for: firstEvent)
        }
      } else if let initialEvent {
        await setupLegacySingleEvent(event: initialEvent)
        loadVisualization(for: initialEvent)
      }

      loadingTask.cancel()
      isReady = true
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

  // MARK: - Visualization

  private func loadVisualization(for event: SnoreEvent?) {
    guard let event else {
      waveformSamples = []
      return
    }
    // Try event clip URL first
    if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
      Task {
        let samples = WaveformGenerator.generateSamples(from: url)
        await MainActor.run {
          waveformSamples = samples
        }
      }
      return
    }
    // Fallback: generate from full session audio if available
    guard let sourceURL = AudioFileURLResolver.resolve(session.audioFileURL) else {
      waveformSamples = []
      return
    }
    Task {
      let samples = await generateWaveformFromSession(sourceURL: sourceURL, event: event)
      await MainActor.run {
        waveformSamples = samples
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

  // MARK: - Clip Playback Helpers

  private func skipClipPlayback(by seconds: TimeInterval) {
    let newTime = max(0, playbackController.currentTime + seconds)
    guard playbackController.totalClipsDuration > 0 else { return }
    let relative = newTime / playbackController.totalClipsDuration
    playbackController.seek(to: relative)
  }

  // MARK: - Legacy Single-Event Playback

  private func setupLegacySingleEvent(event: SnoreEvent) async {
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

      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
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
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
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
