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
  public var currentDB: Float = -160.0
  /// Peak dB of the current buffer (0 dBFS = digital full scale). Tracks impulsive
  /// peaks better than RMS `currentDB`, which is used for intensity classification.
  public var currentPeakDB: Float = -160.0
  /// Spectral snore-likelihood score (0–1). Updated in real-time from FFT analysis.
  public var spectralScore: Float = 0
  public var hasPermission = false
  /// Whether audio is currently being written to a file. Set to false after repeated write failures.
  public var isWritingToFile = false
  /// The event file currently being written to, if any.
  public private(set) var currentEventFile: AVAudioFile?
  public private(set) var currentEventID: UUID?

  private var audioEngine: AVAudioEngine?
  private var audioFile: AVAudioFile?
  private let fftAnalyzer = FFTAnalyzer(bufferSize: 1024)
  private let soundAnalyzer = SoundAnalysisDetector.shared
  private var cumulativeFramePosition: AVAudioFramePosition = 0
  private var recordingFormat: AVAudioFormat?
  private var consecutiveWriteFailures = 0

  private init() {
    checkPermission()
    setupNotifications()
  }

  private func setupNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange),
      name: .AVAudioEngineConfigurationChange,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMelodyWillPlay),
      name: .soothingMelodyWillPlay,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMelodyDidStop),
      name: .soothingMelodyDidStop,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleSessionRouteChange),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
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

  @objc private func handleRouteChange(_ notification: Notification) {
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

    if let audioFileURL = audioFileURL {
      audioFile = try AVAudioFile(forWriting: audioFileURL, settings: format.settings)
    }
    isWritingToFile = audioFile != nil || currentEventFile != nil

    // Tap the microphone directly. A record-only graph that routes the input
    // through to mainMixerNode also feeds the speaker, and relying on volume = 0
    // to mute it leaks — a mic that can hear the speaker forms a feedback loop.
    // Tapping the input node captures full-band audio with no output path at all,
    // so there is nothing to feed back.
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let db = self.calculateDB(from: buffer)
      let peakDB = self.calculatePeakDB(from: buffer)
      let features = self.fftAnalyzer.analyze(buffer: buffer, sampleRate: format.sampleRate)
      self.soundAnalyzer.analyze(buffer: buffer, at: self.cumulativeFramePosition)
      self.cumulativeFramePosition += AVAudioFramePosition(buffer.frameLength)
      var didWrite = false
      if let audioFile = self.audioFile {
        do {
          try audioFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write audio buffer: \(error)")
        }
      }
      if let eventFile = self.currentEventFile {
        do {
          try eventFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write event buffer: \(error)")
        }
      }
      if didWrite {
        self.consecutiveWriteFailures = 0
      } else if self.audioFile != nil || self.currentEventFile != nil {
        self.consecutiveWriteFailures += 1
        if self.consecutiveWriteFailures >= 3 {
          print("[AudioRecorder] Too many write failures — stopping file writes")
          self.isWritingToFile = false
          self.audioFile = nil
          self.currentEventFile = nil
        }
      }
      Task { @MainActor in
        self.currentDB = db
        self.currentPeakDB = peakDB
        self.spectralScore = features.spectralScore
      }
    }

    try engine.start()
    audioEngine = engine
    recordingFormat = format
    soundAnalyzer.startAnalyzing(format: format)
    isRecording = true
    isPaused = false
  }

  public func pauseRecording() {
    guard isRecording, let engine = audioEngine else { return }
    isPaused = true
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

    // Tap the microphone directly — no output path, no feedback (see startRecording).
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let db = self.calculateDB(from: buffer)
      let peakDB = self.calculatePeakDB(from: buffer)
      let features = self.fftAnalyzer.analyze(buffer: buffer, sampleRate: format.sampleRate)
      self.soundAnalyzer.analyze(buffer: buffer, at: self.cumulativeFramePosition)
      self.cumulativeFramePosition += AVAudioFramePosition(buffer.frameLength)
      var didWrite = false
      if let audioFile = self.audioFile {
        do {
          try audioFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write audio buffer: \(error)")
        }
      }
      if let eventFile = self.currentEventFile {
        do {
          try eventFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write event buffer: \(error)")
        }
      }
      if didWrite {
        self.consecutiveWriteFailures = 0
      } else if self.audioFile != nil || self.currentEventFile != nil {
        self.consecutiveWriteFailures += 1
        if self.consecutiveWriteFailures >= 3 {
          print("[AudioRecorder] Too many write failures — stopping file writes")
          self.isWritingToFile = false
          self.audioFile = nil
          self.currentEventFile = nil
        }
      }
      Task { @MainActor in
        self.currentDB = db
        self.spectralScore = features.spectralScore
      }
    }

    try engine.start()
    audioEngine = engine
    recordingFormat = format
    soundAnalyzer.startAnalyzing(format: format)
    isPaused = false
  }

  public func startEventFile(eventID: UUID, url: URL) throws {
    guard let format = recordingFormat else { return }
    currentEventFile = try AVAudioFile(forWriting: url, settings: format.settings)
    currentEventID = eventID
    isWritingToFile = audioFile != nil || currentEventFile != nil
  }

  public func finalizeEventFile() -> URL? {
    let url = currentEventFile?.url
    currentEventFile = nil
    currentEventID = nil
    isWritingToFile = audioFile != nil || currentEventFile != nil
    return url
  }

  public func stopRecording() {
    soundAnalyzer.stopAnalyzing()
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    audioFile = nil
    currentEventFile = nil
    currentEventID = nil
    cumulativeFramePosition = 0
    isRecording = false
    isPaused = false
    isWritingToFile = false
    consecutiveWriteFailures = 0
    currentDB = -160.0
    currentPeakDB = -160.0
    spectralScore = 0

    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func calculateDB(from buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return -160.0 }
    let frameLength = UInt32(buffer.frameLength)
    var sum: Float = 0
    for i in 0..<Int(frameLength) {
      sum += channelData[i] * channelData[i]
    }
    let rms = sqrt(sum / Float(frameLength))
    let db = 20 * log10(max(rms, 1e-10))
    return db
  }

  /// Peak level (0 dBFS = full scale) of the buffer. Better than RMS for
  /// impulsive sounds like snoring, where the perceptual loudness is driven
  /// by sharp peaks rather than average energy.
  private func calculatePeakDB(from buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return -160.0 }
    let frameLength = Int(buffer.frameLength)
    var peak: Float = 0
    for i in 0..<frameLength {
      let absVal = abs(channelData[i])
      if absVal > peak {
        peak = absVal
      }
    }
    let db = 20 * log10(max(peak, 1e-10))
    return db
  }
}
