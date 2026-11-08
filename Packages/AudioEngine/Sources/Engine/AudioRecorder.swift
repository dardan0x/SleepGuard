import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
import Models
import Observation

public enum RecordingError: Error {
  case noMicrophoneInput
  case invalidAudioFormat
}

/// Converts dBFS (negative digital scale) to a 0-100 percentage for UI display.
/// -60 dB → 0%, -20 dB → 100%.
public func audioLevelPercentage(from db: Double) -> Int {
  let normalized = (db + 60.0) / 40.0
  return Int(max(0.0, min(100.0, normalized * 100.0)))
}

public func audioLevelPercentage(from db: Float) -> Int {
  audioLevelPercentage(from: Double(db))
}

@MainActor
@Observable
public final class AudioRecorder {
  public static let shared = AudioRecorder()

  public var isRecording = false
  public var isPaused = false
  public var isWarmedUp = false
  public var currentDB: Float = -160.0
  /// Peak dB of the current buffer (0 dBFS = digital full scale). Tracks impulsive
  /// peaks better than RMS `currentDB`, which is used for intensity classification.
  public var currentPeakDB: Float = -160.0
  /// Spectral snore-likelihood score (0–1). Updated in real-time from FFT analysis.
  public var spectralScore: Float = 0
  public var hasPermission = false
  /// Whether audio is currently being written to a file. Set to false after repeated write failures.
  public var isWritingToFile = false
  public private(set) var currentEventID: UUID?

  private var audioEngine: AVAudioEngine?
  private var warmupEngine: AVAudioEngine?
  private let tap = TapProcessor()
  private let soundAnalyzer = SoundAnalysisDetector.shared
  private var recordingFormat: AVAudioFormat?

  private init() {
    checkPermission()
    setupNotifications()
  }

  private func setupNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange),
      name: .AVAudioEngineConfigurationChange,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMelodyWillPlay),
      name: .snoreInterrupterWillPlay,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMelodyDidStop),
      name: .snoreInterrupterDidStop,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleSessionRouteChange),
      name: AVAudioSession.routeChangeNotification,
      object: nil)
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil)
    #endif
  }

  @objc private func handleMelodyWillPlay() {
    pauseRecording()
  }

  @objc private func handleMelodyDidStop() {
    do {
      try resumeRecording()
    } catch {
      print("[AudioRecorder] resumeRecording() failed after melody: \(error)")
    }
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    switch type {
    case .began:
      // Interruption started — stop engine but keep isRecording flag
      audioEngine?.stop()
    case .ended:
      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      if options.contains(.shouldResume) {
        resumeRecordingIfNeeded()
      }
    @unknown default:
      break
    }
  }

  @objc private func handleRouteChange(_: Notification) {
    resumeRecordingIfNeeded()
  }

  @objc private func handleSessionRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

    switch reason {
    case .newDeviceAvailable, .oldDeviceUnavailable:
      resumeRecordingIfNeeded()
    default:
      break
    }
  }

  #if canImport(UIKit)
  @objc private func handleAppDidBecomeActive() {
    resumeRecordingIfNeeded()
  }
  #endif

  private func resumeRecordingIfNeeded() {
    guard isRecording, !isPaused else { return }
    if let engine = audioEngine, engine.isRunning { return }
    do {
      try resumeRecording()
    } catch {
      print("[AudioRecorder] Failed to resume recording: \(error)")
    }
  }

  public func checkPermission() {
    #if targetEnvironment(simulator)
    hasPermission = true
    #else
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      hasPermission = true
    case .denied, .undetermined:
      hasPermission = false
    @unknown default:
      hasPermission = false
    }
    #endif
  }

  public func requestPermission() async -> Bool {
    #if targetEnvironment(simulator)
    hasPermission = true
    return true
    #else
    let granted = await withCheckedContinuation { continuation in
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        continuation.resume(returning: granted)
      }
    }
    hasPermission = granted
    return granted
    #endif
  }

  public func startRecording(audioFileURL: URL? = nil) throws {
    guard hasPermission else { return }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
    try session.setActive(true)

    #if !targetEnvironment(simulator)
    guard !session.currentRoute.inputs.isEmpty else {
      throw RecordingError.noMicrophoneInput
    }
    #endif

    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)

    guard format.channelCount > 0, format.sampleRate > 0 else {
      throw RecordingError.invalidAudioFormat
    }

    if let audioFileURL {
      tap.audioFile = try AVAudioFile(forWriting: audioFileURL, settings: format.settings)
    }
    isWritingToFile = tap.isWritingToFile

    // Tap the microphone directly. A record-only graph that routes the input
    // through to mainMixerNode also feeds the speaker, and relying on volume = 0
    // to mute it leaks — a mic that can hear the speaker forms a feedback loop.
    // Tapping the input node captures full-band audio with no output path at all,
    // so there is nothing to feed back.
    installTap(on: input, format: format)
    try engine.start()
    audioEngine = engine
    recordingFormat = format
    tap.streamAnalyzer = soundAnalyzer.startAnalyzing(format: format)
    isRecording = true
    isPaused = false
  }

  public func pauseRecording() {
    guard isRecording, let engine = audioEngine else { return }
    isPaused = true
    tap.streamAnalyzer = nil
    soundAnalyzer.stopAnalyzing()
    engine.stop()
    // Remove the tap from the input node so the engine can be safely deallocated.
    // AVAudioEngine cannot be reliably restarted after stop() when a tap is installed.
    engine.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    // audioFile is intentionally kept alive so resumeRecording() can continue appending.
  }

  public func resumeRecording() throws {
    guard isRecording else { return }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
    try session.setActive(true)

    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)

    guard format.channelCount > 0, format.sampleRate > 0 else {
      throw RecordingError.invalidAudioFormat
    }

    installTap(on: input, format: format)
    try engine.start()
    audioEngine = engine
    recordingFormat = format
    tap.streamAnalyzer = soundAnalyzer.startAnalyzing(format: format)
    isPaused = false
  }

  public func startEventFile(eventID: UUID, url: URL) throws {
    guard let format = recordingFormat else { return }
    tap.eventFile = try AVAudioFile(forWriting: url, settings: format.settings)
    currentEventID = eventID
    isWritingToFile = tap.isWritingToFile
  }

  public func finalizeEventFile() -> URL? {
    let url = tap.eventFile?.url
    tap.eventFile = nil
    currentEventID = nil
    isWritingToFile = tap.isWritingToFile
    return url
  }

  public func stopRecording() {
    tap.reset()
    soundAnalyzer.stopAnalyzing()
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    currentEventID = nil
    isRecording = false
    isPaused = false
    isWritingToFile = false
    currentDB = -160.0
    currentPeakDB = -160.0
    spectralScore = 0

    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  // MARK: - Warmup (keeps audio I/O alive during a delayed-start countdown)

  /// Activates the audio session and starts a minimal input engine so the app
  /// remains eligible for background audio execution while the user-configured
  /// recording delay counts down. Buffers are discarded; no file is written and
  /// no detection is run.
  public func startWarmup() throws {
    guard hasPermission else { return }
    guard !isWarmedUp, warmupEngine == nil else { return }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
    try session.setActive(true)

    #if !targetEnvironment(simulator)
    guard !session.currentRoute.inputs.isEmpty else {
      throw RecordingError.noMicrophoneInput
    }
    #endif

    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)

    guard format.channelCount > 0, format.sampleRate > 0 else {
      throw RecordingError.invalidAudioFormat
    }

    // Tap the input to keep I/O alive, but discard every buffer. No analysis,
    // no file writes — the countdown view handles the timer.
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable _, _ in
      // Intentionally empty.
    }

    try engine.start()
    warmupEngine = engine
    isWarmedUp = true
  }

  /// Stops the warmup engine and tears down the input tap. Deactivates the
  /// audio session only if a real recording is not currently in progress.
  public func stopWarmup() {
    guard isWarmedUp else { return }
    warmupEngine?.stop()
    warmupEngine?.inputNode.removeTap(onBus: 0)
    warmupEngine = nil
    isWarmedUp = false
    if !isRecording {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }

  // MARK: - Tap

  /// Core Audio calls the tap on its realtime thread, so the closure must be
  /// `@Sendable` (nonisolated); all buffer work happens in `TapProcessor`.
  /// It taps the microphone directly — no output path, no feedback.
  private func installTap(on input: AVAudioInputNode, format: AVAudioFormat) {
    let tap = tap
    let sampleRate = format.sampleRate
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable [weak self] buffer, _ in
      let levels = tap.process(buffer, sampleRate: sampleRate)
      Task { @MainActor in
        guard let self else { return }
        self.currentDB = levels.db
        self.currentPeakDB = levels.peakDB
        self.spectralScore = levels.spectralScore
        if levels.writesDisabled {
          self.isWritingToFile = false
        }
      }
    }
  }
}
