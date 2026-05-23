import AVFoundation
import Models
import Observation

/// Manages sequential playback of snore-event audio clips.
@MainActor
@Observable
public final class ClipPlaybackController {
  public var events: [SnoreEvent] = []
  public var currentEventIndex: Int = 0
  public var isPlaying: Bool = false
  public var currentClipTime: TimeInterval = 0
  public var totalClipsDuration: TimeInterval = 0

  private var audioPlayer: AVAudioPlayer?
  private var progressTimer: Timer?
  private var clipDurations: [TimeInterval] = []
  private var notificationObserver: NSObjectProtocol?

  public init() {}

  public var currentEvent: SnoreEvent? {
    events.indices.contains(currentEventIndex) ? events[currentEventIndex] : nil
  }

  public var currentEventNumber: Int {
    currentEventIndex + 1
  }

  public var totalEventCount: Int {
    events.count
  }

  /// Cumulative time of all clips before the current one.
  public var currentClipStartTime: TimeInterval {
    clipDurations.prefix(currentEventIndex).reduce(0, +)
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
    // Caller already sorts events; trust the order to avoid redundant work.
    self.events = events
    // Use event.duration as the single source of truth so the player's total
    // matches session.snoringDuration and the stats grid.
    // Skip file-existence checks; assume clips exist. Missing clips fail gracefully at play time.
    clipDurations = events.map { $0.snoreDuration }
    totalClipsDuration = clipDurations.reduce(0, +)
    currentEventIndex = 0
    currentClipTime = 0
    // Lazy: don't create AVAudioPlayer until user taps play.
  }

  public var hasAudioForCurrentEvent: Bool {
    guard let event = currentEvent else { return false }
    return AudioFileURLResolver.resolve(event.audioFileURL) != nil
  }

  public func play() {
    if audioPlayer == nil {
      setupPlayerForCurrentEvent()
    }
    guard let player = audioPlayer else {
      print("[ClipPlaybackController] Cannot play: audioPlayer is nil (missing file for event \(currentEvent?.id.uuidString ?? "nil"))")
      return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      // Deactivate first to clear any stale simulator session state
      try? session.setActive(false)
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      print("[ClipPlaybackController] Audio session setup failed: \(error)")
    }
    guard player.play() else {
      print("[ClipPlaybackController] player.play() returned false")
      return
    }
    isPlaying = true
    print("[ClipPlaybackController] Playback started for event \(currentEvent?.id.uuidString ?? "nil")")
    startProgressTimer()
  }

  public func pause() {
    audioPlayer?.pause()
    isPlaying = false
    stopProgressTimer()
  }

  public func togglePlayback() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  /// Alias for togglePlayback.
  public func toggle() {
    togglePlayback()
  }

  public func playEvent(at index: Int) {
    guard events.indices.contains(index) else { return }
    currentEventIndex = index
    currentClipTime = 0
    setupPlayerForCurrentEvent()
    play()
  }

  public func nextEvent() {
    playEvent(at: currentEventIndex + 1)
  }

  public func previousEvent() {
    playEvent(at: currentEventIndex - 1)
  }

  /// Seeks to a relative position (0–1) across the concatenated timeline.
  public func seek(to relative: Double) {
    seekToOverall(relative: relative)
  }

  /// Seeks to a relative position (0–1) across the concatenated timeline.
  public func seekToOverall(relative: Double) {
    guard totalClipsDuration > 0, !clipDurations.isEmpty else { return }
    let targetTime = relative * totalClipsDuration

    var accumulated: TimeInterval = 0
    for (index, duration) in clipDurations.enumerated() {
      if accumulated + duration >= targetTime {
        let clipOffset = targetTime - accumulated
        if currentEventIndex != index {
          currentEventIndex = index
          setupPlayerForCurrentEvent()
        }
        audioPlayer?.currentTime = max(0, min(clipOffset, duration))
        currentClipTime = audioPlayer?.currentTime ?? clipOffset
        if isPlaying {
          audioPlayer?.play()
        }
        return
      }
      accumulated += duration
    }
    // Seek to end
    currentEventIndex = clipDurations.count - 1
    setupPlayerForCurrentEvent()
    audioPlayer?.currentTime = clipDurations.last ?? 0
    currentClipTime = audioPlayer?.currentTime ?? 0
  }

  /// Seeks within the current clip (0–1).
  public func seekInCurrentClip(relative: Double) {
    guard let player = audioPlayer else { return }
    let time = relative * player.duration
    player.currentTime = max(0, min(time, player.duration))
    currentClipTime = player.currentTime
  }

  public func cleanup() {
    pause()
    notificationObserver.map { NotificationCenter.default.removeObserver($0) }
    notificationObserver = nil
    audioPlayer = nil
  }

  // MARK: - Private

  private func setupPlayerForCurrentEvent() {
    notificationObserver.map { NotificationCenter.default.removeObserver($0) }
    notificationObserver = nil
    audioPlayer = nil

    guard let event = currentEvent else {
      print("[ClipPlaybackController] setupPlayer: no current event")
      return
    }
    guard let url = AudioFileURLResolver.resolve(event.audioFileURL) else {
      print("[ClipPlaybackController] setupPlayer: no audio file for event \(event.id)")
      return
    }

    // Configure audio session BEFORE creating AVAudioPlayer.
    // On Simulator, a stale .playAndRecord session can prevent playback.
    do {
      let session = AVAudioSession.sharedInstance()
      try? session.setActive(false)
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      print("[ClipPlaybackController] Audio session setup failed: \(error)")
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      audioPlayer = player
      currentClipTime = 0
      // Clip may include breathing gaps, so actual duration can exceed snoreDuration.
      if clipDurations.indices.contains(currentEventIndex) {
        clipDurations[currentEventIndex] = player.duration
        totalClipsDuration = clipDurations.reduce(0, +)
      }
      print("[ClipPlaybackController] Player ready for event \(event.id), file: \(url.lastPathComponent), duration: \(player.duration)s")

      notificationObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.isPlaying = false
        self?.stopProgressTimer()
      }
    } catch {
      print("[ClipPlaybackController] Failed to create AVAudioPlayer for \(url.lastPathComponent): \(error)")
      audioPlayer = nil
    }
  }

  private func startProgressTimer() {
    stopProgressTimer()
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.tick()
      }
    }
  }

  private func stopProgressTimer() {
    progressTimer?.invalidate()
    progressTimer = nil
  }

  private func tick() {
    guard let player = audioPlayer else { return }
    currentClipTime = player.currentTime

    // Auto-advance to next clip only when we're actually near the end
    let currentDuration = audioPlayer?.duration ?? (clipDurations.indices.contains(currentEventIndex) ? clipDurations[currentEventIndex] : 0)
    if !player.isPlaying, isPlaying, currentDuration > 0, currentClipTime >= currentDuration - 0.3 {
      if currentEventIndex + 1 < events.count {
        currentEventIndex += 1
        setupPlayerForCurrentEvent()
        audioPlayer?.play()
      } else {
        isPlaying = false
        stopProgressTimer()
        currentClipTime = 0
        currentEventIndex = 0
        setupPlayerForCurrentEvent()
      }
    }
  }
}
