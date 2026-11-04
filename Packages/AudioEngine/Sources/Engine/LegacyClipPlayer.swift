import AVFoundation
import Foundation
import Models

/// Plays a single snore-event clip exported from a full session recording.
/// Used for sessions that predate per-event clip extraction, where the only
/// audio source is the raw session file: `prepare` exports the event span via
/// `AudioClipExtractor`, then plays it through `AVAudioPlayer` while tracking
/// playback progress.
@MainActor
@Observable
public final class LegacyClipPlayer {
  public private(set) var isPlaying = false
  public private(set) var currentTime: TimeInterval = 0
  public private(set) var duration: TimeInterval = 0

  private var player: AVAudioPlayer?
  private var progressTask: Task<Void, Never>?

  public init() {}

  /// Exports the event's audio from the session file and starts playback.
  /// Leaves `duration` at 0 when the export or player setup fails.
  public func prepare(event: SnoreEvent, sessionURL: URL?, sessionStart: Date) async {
    guard let sessionURL else { return }
    // Destructure Sendable fields before crossing into the extractor — a
    // SwiftData @Model class cannot be sent across isolation boundaries.
    let eventID = event.id
    let eventTimestamp = event.timestamp
    let eventSnoreDuration = event.snoreDuration
    let eventBursts = event.bursts
    let totalDuration = AVURLAsset(url: sessionURL).duration.seconds
    let result = await AudioClipExtractor.extractSingleClip(
      eventID: eventID,
      eventTimestamp: eventTimestamp,
      eventSnoreDuration: eventSnoreDuration,
      bursts: eventBursts,
      sessionURL: sessionURL,
      sessionStart: sessionStart,
      totalDuration: totalDuration,
      padding: 0,
      outputDirectory: FileManager.default.temporaryDirectory)
    guard let result else { return }

    do {
      let player = try AVAudioPlayer(contentsOf: result.clipURL)
      player.prepareToPlay()
      self.player = player
      duration = player.duration
      currentTime = 0
      activatePlaybackSession()
      player.play()
      isPlaying = true
      startProgressLoop()
    } catch {
      player = nil
      duration = 0
    }
  }

  public func toggle() {
    guard let player else { return }
    if player.isPlaying {
      player.pause()
      isPlaying = false
      progressTask?.cancel()
    } else {
      activatePlaybackSession()
      player.play()
      isPlaying = true
      startProgressLoop()
    }
  }

  public func skip(by seconds: TimeInterval) {
    guard let player else { return }
    let newTime = max(0, min(player.currentTime + seconds, player.duration))
    player.currentTime = newTime
    currentTime = newTime
  }

  public func scrubTo(relative: Double) {
    guard let player else { return }
    let time = relative * player.duration
    player.currentTime = max(0, min(time, player.duration))
    currentTime = player.currentTime
  }

  public func stop() {
    progressTask?.cancel()
    player?.stop()
    isPlaying = false
  }

  private func activatePlaybackSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(false)
    try? session.setCategory(.playback, mode: .default)
    try? session.setActive(true)
  }

  private func startProgressLoop() {
    progressTask?.cancel()
    progressTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(100))
        guard let player, !Task.isCancelled else { return }
        currentTime = player.currentTime
        if !player.isPlaying {
          isPlaying = false
          return
        }
      }
    }
  }
}
