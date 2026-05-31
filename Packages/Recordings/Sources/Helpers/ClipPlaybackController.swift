import AVFoundation
import Models
import Observation

/// Manages sequential playback of snore-event audio clips.
///
/// Routes each clip through `AVAudioEngine` so that an optional enhancement
/// chain (high-pass 80 Hz + low-pass 1.5 kHz + per-clip peak normalization,
/// capped at +24 dB) can be applied without modifying the saved `.m4a` files.
/// When `enhancedAudioEnabled` is `false`, the EQ bands and global gain are
/// bypassed and playback is bit-exact to the recorded clip.
@MainActor
@Observable
public final class ClipPlaybackController {
  public var events: [SnoreEvent] = []
  public var currentEventIndex: Int = 0
  public var isPlaying: Bool = false
  public var currentClipTime: TimeInterval = 0
  public var totalClipsDuration: TimeInterval = 0

  /// When `true`, clips play through band-pass (80 Hz–1.5 kHz) + per-clip
  /// peak normalization (target −3 dBFS, capped at +24 dB EQ headroom).
  /// When `false`, raw playback.
  public var enhancedAudioEnabled: Bool = true {
    didSet {
      guard oldValue != enhancedAudioEnabled else { return }
      applyEnhancementToggle()
      // Recompute per-clip gain in case current clip is loaded.
      if let file = audioFile { eq.globalGain = currentGainDB(for: file) }
    }
  }

  // MARK: - Audio pipeline

  private let engine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let eq = AVAudioUnitEQ(numberOfBands: 2)
  private var connectedFormat: AVAudioFormat?

  // MARK: - Current clip state

  private var audioFile: AVAudioFile?
  private var currentFileDuration: TimeInterval = 0
  private var pausedAtClipTime: TimeInterval = 0
  private var playbackStartHostTime: TimeInterval = 0
  private var playbackStartClipTime: TimeInterval = 0
  /// Monotonic token to discard stale `scheduleSegment` completions when we
  /// stop or re-schedule before the prior segment finished.
  private var playbackToken: Int = 0

  // MARK: - Aggregate state

  private var progressTimer: Timer?
  private var clipDurations: [TimeInterval] = []
  private var notificationObserver: NSObjectProtocol?

  public init() {
    engine.attach(playerNode)
    engine.attach(eq)

    // High-pass at 80 Hz kills HVAC rumble + 50/60 Hz mains hum.
    // Low-pass at 1.5 kHz kills broadband mic hiss.
    // Snore energy lives 100 Hz–1 kHz so this passband preserves all of it.
    let hp = eq.bands[0]
    hp.filterType = .highPass
    hp.frequency = 80
    hp.bandwidth = 1.0
    hp.gain = 0

    let lp = eq.bands[1]
    lp.filterType = .lowPass
    lp.frequency = 1500
    lp.bandwidth = 1.0
    lp.gain = 0

    applyEnhancementToggle()
  }

  public var currentEvent: SnoreEvent? {
    events.indices.contains(currentEventIndex) ? events[currentEventIndex] : nil
  }

  public var currentEventNumber: Int { currentEventIndex + 1 }

  public var totalEventCount: Int { events.count }

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
    self.events = events
    clipDurations = events.map { $0.snoreDuration }
    totalClipsDuration = clipDurations.reduce(0, +)
    currentEventIndex = 0
    currentClipTime = 0
    pausedAtClipTime = 0
    audioFile = nil
    // Lazy: actual file load happens on first play().
  }

  public var hasAudioForCurrentEvent: Bool {
    guard let event = currentEvent else { return false }
    return AudioFileURLResolver.resolve(event.audioFileURL) != nil
  }

  public func play() {
    if audioFile == nil {
      setupPlayerForCurrentEvent()
    }
    guard let file = audioFile else {
      print("[ClipPlaybackController] Cannot play: no file (event \(currentEvent?.id.uuidString ?? "nil"))")
      return
    }

    do {
      try configurePlaybackSession()
      if !engine.isRunning {
        try engine.start()
      }

      let sampleRate = file.processingFormat.sampleRate
      let startFrame = AVAudioFramePosition(pausedAtClipTime * sampleRate)
      let remaining = file.length - startFrame
      guard remaining > 0 else {
        // Already at or past end — auto-advance.
        handlePlaybackFinished()
        return
      }

      playbackToken &+= 1
      let token = playbackToken

      playerNode.stop() // discard any prior scheduling
      // `.dataPlayedBack` fires AFTER the audio has actually been heard, not
      // when it's been read from the file (the default `.dataConsumed`). This
      // prevents auto-advance / engine reconnect from chopping off the tail
      // of the clip (the engine's output buffer is still draining when
      // `.dataConsumed` fires).
      playerNode.scheduleSegment(
        file,
        startingFrame: startFrame,
        frameCount: AVAudioFrameCount(remaining),
        at: nil,
        completionCallbackType: .dataPlayedBack
      ) { [weak self] _ in
        Task { @MainActor in
          guard let self else { return }
          guard self.playbackToken == token else { return } // stale completion
          self.handlePlaybackFinished()
        }
      }
      playerNode.play()

      playbackStartHostTime = ProcessInfo.processInfo.systemUptime
      playbackStartClipTime = pausedAtClipTime
      isPlaying = true
      startProgressTimer()
      print("[ClipPlaybackController] Play from \(pausedAtClipTime)s (gain \(eq.globalGain) dB, enhanced=\(enhancedAudioEnabled))")
    } catch {
      print("[ClipPlaybackController] play failed: \(error)")
    }
  }

  public func pause() {
    guard isPlaying else { return }
    let now = ProcessInfo.processInfo.systemUptime
    pausedAtClipTime = min(playbackStartClipTime + (now - playbackStartHostTime), currentFileDuration)
    currentClipTime = pausedAtClipTime
    playbackToken &+= 1 // invalidate the in-flight segment's completion
    playerNode.pause()
    isPlaying = false
    stopProgressTimer()
  }

  public func togglePlayback() {
    if isPlaying { pause() } else { play() }
  }

  /// Alias for togglePlayback.
  public func toggle() { togglePlayback() }

  public func playEvent(at index: Int) {
    guard events.indices.contains(index) else { return }
    currentEventIndex = index
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
    guard totalClipsDuration > 0, !clipDurations.isEmpty else { return }
    let targetTime = relative * totalClipsDuration

    var accumulated: TimeInterval = 0
    for (index, duration) in clipDurations.enumerated() {
      if accumulated + duration >= targetTime {
        let clipOffset = targetTime - accumulated
        let wasPlaying = isPlaying
        if wasPlaying { pause() }
        if currentEventIndex != index {
          currentEventIndex = index
          setupPlayerForCurrentEvent()
        }
        pausedAtClipTime = max(0, min(clipOffset, currentFileDuration))
        currentClipTime = pausedAtClipTime
        if wasPlaying { play() }
        return
      }
      accumulated += duration
    }
    // Past the end
    currentEventIndex = max(0, clipDurations.count - 1)
    setupPlayerForCurrentEvent()
    pausedAtClipTime = currentFileDuration
    currentClipTime = pausedAtClipTime
  }

  /// Seeks within the current clip (0–1).
  public func seekInCurrentClip(relative: Double) {
    guard audioFile != nil else { return }
    let target = relative * currentFileDuration
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    pausedAtClipTime = max(0, min(target, currentFileDuration))
    currentClipTime = pausedAtClipTime
    if wasPlaying { play() }
  }

  public func cleanup() {
    pause()
    playbackToken &+= 1
    playerNode.stop()
    if engine.isRunning { engine.stop() }
    notificationObserver.map { NotificationCenter.default.removeObserver($0) }
    notificationObserver = nil
    audioFile = nil
  }

  // MARK: - Private

  /// Applies the bypass state to the EQ chain — used when the user toggles
  /// `enhancedAudioEnabled`. Per-clip gain is recomputed separately.
  private func applyEnhancementToggle() {
    let bypass = !enhancedAudioEnabled
    eq.bands[0].bypass = bypass
    eq.bands[1].bypass = bypass
    eq.bypass = bypass
    if bypass { eq.globalGain = 0 }
  }

  private func setupPlayerForCurrentEvent() {
    playbackToken &+= 1
    if playerNode.isPlaying { playerNode.stop() }
    notificationObserver.map { NotificationCenter.default.removeObserver($0) }
    notificationObserver = nil
    audioFile = nil

    guard let event = currentEvent else {
      print("[ClipPlaybackController] setupPlayer: no current event")
      return
    }
    guard let url = AudioFileURLResolver.resolve(event.audioFileURL) else {
      print("[ClipPlaybackController] setupPlayer: no audio file for event \(event.id)")
      return
    }

    do {
      let file = try AVAudioFile(forReading: url)
      audioFile = file
      currentFileDuration = TimeInterval(file.length) / file.processingFormat.sampleRate
      if clipDurations.indices.contains(currentEventIndex) {
        clipDurations[currentEventIndex] = currentFileDuration
        totalClipsDuration = clipDurations.reduce(0, +)
      }
      currentClipTime = 0
      pausedAtClipTime = 0

      try connectChain(format: file.processingFormat)
      eq.globalGain = currentGainDB(for: file)

      try configurePlaybackSession()

      notificationObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          self?.isPlaying = false
          self?.stopProgressTimer()
        }
      }
      print("[ClipPlaybackController] Loaded \(url.lastPathComponent), \(currentFileDuration)s, gain \(eq.globalGain) dB")
    } catch {
      print("[ClipPlaybackController] Failed to load \(url.lastPathComponent): \(error)")
      audioFile = nil
    }
  }

  /// Connects `playerNode → eq → mainMixerNode` with the given format if not
  /// already connected at that format. Safe to call repeatedly; no-ops when
  /// the format hasn't changed (sample rate / channel count / common format).
  private func connectChain(format: AVAudioFormat) throws {
    if let cur = connectedFormat,
       cur.sampleRate == format.sampleRate,
       cur.channelCount == format.channelCount,
       cur.commonFormat == format.commonFormat
    {
      return
    }
    if engine.isRunning { engine.stop() }
    engine.disconnectNodeInput(eq)
    engine.disconnectNodeInput(engine.mainMixerNode)
    engine.connect(playerNode, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    connectedFormat = format
  }

  private func configurePlaybackSession() throws {
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(false)
    try session.setCategory(.playback, mode: .default)
    try session.setActive(true)
  }

  /// dB gain to bring this clip's peak amplitude to −3 dBFS, capped at the
  /// EQ's +24 dB ceiling. Returns 0 (no gain) when enhancement is off or
  /// the clip is silent / unreadable.
  private func currentGainDB(for file: AVAudioFile) -> Float {
    guard enhancedAudioEnabled else { return 0 }
    let length = AVAudioFrameCount(file.length)
    guard length > 0,
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: length)
    else { return 0 }

    let saved = file.framePosition
    defer { file.framePosition = saved }
    file.framePosition = 0
    do { try file.read(into: buffer) } catch { return 0 }

    var peak: Float = 0
    if let channels = buffer.floatChannelData {
      let frames = Int(buffer.frameLength)
      let count = Int(buffer.format.channelCount)
      for c in 0..<count {
        let p = channels[c]
        for i in 0..<frames {
          let amp = abs(p[i])
          if amp > peak { peak = amp }
        }
      }
    }
    guard peak > 0 else { return 0 }

    // Target peak: −3 dBFS ≈ 0.708. Never attenuate (>= 0). Cap at +24 dB.
    let target: Float = 0.708
    let gainLinear = target / peak
    let gainDB = 20 * log10(gainLinear)
    return min(max(gainDB, 0), 24)
  }

  private func handlePlaybackFinished() {
    pausedAtClipTime = 0
    if currentEventIndex + 1 < events.count {
      currentEventIndex += 1
      currentClipTime = 0
      setupPlayerForCurrentEvent()
      play()
    } else {
      isPlaying = false
      currentClipTime = 0
      currentEventIndex = 0
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
    guard isPlaying, audioFile != nil else { return }
    let now = ProcessInfo.processInfo.systemUptime
    let elapsed = now - playbackStartHostTime
    currentClipTime = min(playbackStartClipTime + elapsed, currentFileDuration)
  }
}
