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
    self.events = events.sorted { $0.timestamp < $1.timestamp }
    // Use event.duration as the single source of truth so the player's total
    // matches session.snoringDuration and the stats grid.
    clipDurations = self.events.map { event in
      guard AudioFileURLResolver.resolve(event.audioFileURL) != nil else { return 0 }
      return event.snoreDuration
    }
    totalClipsDuration = clipDurations.reduce(0, +)
    currentEventIndex = 0
    currentClipTime = 0
    setupPlayerForCurrentEvent()
  }

  public func play() {
    guard let player = audioPlayer else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Continue anyway; playback may still work
    }
    guard player.play() else { return }
    isPlaying = true
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

    guard let event = currentEvent,
          let url = AudioFileURLResolver.resolve(event.audioFileURL) else { return }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      audioPlayer = player
      currentClipTime = 0

      notificationObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.isPlaying = false
        self?.stopProgressTimer()
      }
    } catch {
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
    let currentDuration = clipDurations.indices.contains(currentEventIndex) ? clipDurations[currentEventIndex] : 0
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
