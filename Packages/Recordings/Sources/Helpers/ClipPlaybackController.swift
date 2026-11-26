public import Foundation
public import Models
public import Observation
import SleepAudioKit
import SleepCore

/// Manages sequential playback of snore-event audio clips.
///
/// Each clip plays through SleepGuardShared's `ClipPlayerEngine` (the same as
/// SleepGuardUIKitWay's): an optional enhancement chain (high-pass 80 Hz +
/// low-pass 1.5 kHz + per-clip peak boost, capped at +24 dB) without changing
/// the saved `.m4a` files; off, playback is bit-exact to the recorded clip.
///
/// The playback rules (joined timeline, seeking, auto-advance) are SleepCore's
/// `ClipPlaylist`; this class keeps the screen's state over the engine.
@MainActor
@Observable
public final class ClipPlaybackController {
  public var events: [SnoreEvent] = []
  public var isPlaying = false
  public var currentClipTime: TimeInterval = 0
  /// Which clip is current and the joined timeline (SleepCore).
  private var playlist = ClipPlaylist(clips: [])

  public var currentEventIndex: Int {
    playlist.index
  }

  public var totalClipsDuration: TimeInterval {
    playlist.totalDuration
  }

  /// When `true`, clips play through band-pass (80 Hz–1.5 kHz) + per-clip
  /// peak normalization (target −3 dBFS, capped at +24 dB EQ headroom).
  /// When `false`, raw playback.
  public var enhancedAudioEnabled = true {
    didSet {
      guard oldValue != enhancedAudioEnabled else { return }
      player.isEnhanced = enhancedAudioEnabled
    }
  }

  // MARK: - Audio

  private let player = ClipPlayerEngine()
  /// The current event's clip is loaded into `player`.
  private var isLoaded = false
  private var currentFileDuration: TimeInterval = 0
  /// Algorithm-defined playback duration for the current clip.
  /// Falls back to the actual file duration if the clip duration is missing.
  private var currentClipDuration: TimeInterval {
    guard let clip = playlist.current else { return currentFileDuration }
    return min(clip.duration, currentFileDuration)
  }

  private var pausedAtClipTime: TimeInterval = 0

  // MARK: - Aggregate state

  private var progressTimer: Timer?

  public init() {
    player.onInterruption = { [weak self] in
      guard let self else { return }
      pausedAtClipTime = min(player.position, currentClipDuration)
      currentClipTime = pausedAtClipTime
      isPlaying = false
      stopProgressTimer()
    }
  }

  public var currentEvent: SnoreEvent? {
    events.indices.contains(playlist.index) ? events[playlist.index] : nil
  }

  public var currentEventNumber: Int { currentEventIndex + 1 }

  public var totalEventCount: Int { events.count }

  /// Cumulative time of all clips before the current one.
  public var currentClipStartTime: TimeInterval {
    playlist.currentClipStart
  }

  /// Current playback time across the concatenated timeline.
  public var currentTime: TimeInterval {
    currentClipStartTime + currentClipTime
  }

  /// Progress through the entire concatenated timeline (0–1).
  public var overallProgress: Double {
    guard totalClipsDuration > 0 else { return 0 }
    return (currentClipStartTime + currentClipTime) / totalClipsDuration
  }

  public func loadEvents(_ events: [SnoreEvent]) {
    self.events = events
    playlist = ClipPlaylist(clips: events.map { ClipPlaylist.Clip(id: $0.id, fileName: nil, duration: $0.snoreDuration) })
    currentClipTime = 0
    pausedAtClipTime = 0
    isLoaded = false
    // Lazy: actual file load happens on first play().
  }

  public var hasAudioForCurrentEvent: Bool {
    guard let event = currentEvent else { return false }
    return AudioFileURLResolver.resolve(event.audioFileURL) != nil
  }

  public func play() {
    if !isLoaded {
      setupPlayerForCurrentEvent()
    }
    guard isLoaded else {
      Log.playback.error("Cannot play: no file (event \(self.currentEvent?.id.uuidString ?? "nil"))")
      return
    }
    let remaining = currentClipDuration - pausedAtClipTime
    guard remaining > 0 else {
      // Already at or past end — auto-advance.
      handlePlaybackFinished()
      return
    }
    do {
      try player.play(from: pausedAtClipTime, for: remaining) { [weak self] in self?.handlePlaybackFinished() }
      isPlaying = true
      startProgressTimer()
      Log.playback.debug("Play from \(self.pausedAtClipTime)s (gain \(self.player.boostDB) dB, enhanced=\(self.enhancedAudioEnabled))")
    } catch {
      Log.playback.error("play failed: \(String(describing: error), privacy: .public)")
    }
  }

  public func pause() {
    guard isPlaying else { return }
    player.pause()
    pausedAtClipTime = min(player.position, currentClipDuration)
    currentClipTime = pausedAtClipTime
    isPlaying = false
    stopProgressTimer()
  }

  public func togglePlayback() {
    if isPlaying { pause() } else { play() }
  }

  /// Alias for togglePlayback.
  public func toggle() { togglePlayback() }

  public func playEvent(at index: Int) {
    guard playlist.select(index) else { return }
    currentClipTime = 0
    pausedAtClipTime = 0
    setupPlayerForCurrentEvent()
    play()
  }

  public func nextEvent() { playEvent(at: currentEventIndex + 1) }
  public func previousEvent() { playEvent(at: currentEventIndex - 1) }

  /// Seeks to a relative position (0–1) across the concatenated timeline.
  public func seek(to relative: Double) {
    seekToOverall(relative: relative)
  }

  /// Seeks to a relative position (0–1) across the concatenated timeline.
  public func seekToOverall(relative: Double) {
    guard playlist.totalDuration > 0, !playlist.clips.isEmpty else { return }
    // Past the end: the end of the last clip, playback left as it was.
    guard relative <= 1 else {
      playlist.seek(toProgress: relative)
      setupPlayerForCurrentEvent()
      pausedAtClipTime = currentClipDuration
      currentClipTime = pausedAtClipTime
      return
    }
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    let previousIndex = playlist.index
    playlist.seek(toProgress: relative)
    if playlist.index != previousIndex {
      setupPlayerForCurrentEvent()
    }
    pausedAtClipTime = max(0, min(playlist.offset, currentClipDuration))
    currentClipTime = pausedAtClipTime
    if wasPlaying { play() }
  }

  /// Seeks within the current clip (0–1).
  public func seekInCurrentClip(relative: Double) {
    guard isLoaded else { return }
    let target = relative * currentClipDuration
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    pausedAtClipTime = max(0, min(target, currentClipDuration))
    currentClipTime = pausedAtClipTime
    if wasPlaying { play() }
  }

  public func cleanup() {
    pause()
    player.stop()
    isLoaded = false
  }

  // MARK: - Private

  private func setupPlayerForCurrentEvent() {
    player.pause()
    isLoaded = false

    guard let event = currentEvent else {
      Log.playback.debug("setupPlayer: no current event")
      return
    }
    guard let url = AudioFileURLResolver.resolve(event.audioFileURL) else {
      Log.playback.debug("setupPlayer: no audio file for event \(event.id)")
      return
    }

    do {
      currentFileDuration = try player.load(url)
      isLoaded = true
      currentClipTime = 0
      pausedAtClipTime = 0
      Log.playback.debug("Loaded \(url.lastPathComponent), \(self.currentFileDuration)s, gain \(self.player.boostDB) dB")
    } catch {
      Log.playback.error("Failed to load \(url.lastPathComponent): \(String(describing: error), privacy: .public)")
    }
  }

  private func handlePlaybackFinished() {
    pausedAtClipTime = 0
    switch playlist.clipFinished() {
    case .playNext:
      currentClipTime = 0
      setupPlayerForCurrentEvent()
      play()
    case .stopAtStart:
      isPlaying = false
      currentClipTime = 0
      stopProgressTimer()
      setupPlayerForCurrentEvent()
    }
  }

  private func startProgressTimer() {
    stopProgressTimer()
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.tick() }
    }
  }

  private func stopProgressTimer() {
    progressTimer?.invalidate()
    progressTimer = nil
  }

  private func tick() {
    guard isPlaying, isLoaded else { return }
    currentClipTime = min(player.position, currentClipDuration)
  }
}
