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
  /// Spectral snore-likelihood score (0–1). Updated in real-time from FFT analysis.
  public var spectralScore: Float = 0
  public var hasPermission = false

  private var audioEngine: AVAudioEngine?
  private var audioFile: AVAudioFile?
  private let fftAnalyzer = FFTAnalyzer(bufferSize: 1024)
  private let soundAnalyzer = SoundAnalysisDetector.shared
  private var cumulativeFramePosition: AVAudioFramePosition = 0
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

    // Bandpass filter for snoring frequencies (100–500 Hz).
    // Apple's built-in classifier already focuses on this band;
    // filtering the recording removes non-snore noise.
    let eq = AVAudioUnitEQ(numberOfBands: 1)
    let band = eq.bands[0]
    band.filterType = .bandPass
    band.frequency = 300
    band.bandwidth = 2.5
    band.gain = 0
    band.bypass = false
    engine.attach(eq)
    engine.connect(input, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    engine.mainMixerNode.volume = 0

    if let audioFileURL = audioFileURL {
      audioFile = try AVAudioFile(forWriting: audioFileURL, settings: format.settings)
    }

    eq.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let db = self.calculateDB(from: buffer)
      let features = self.fftAnalyzer.analyze(buffer: buffer, sampleRate: format.sampleRate)
      self.soundAnalyzer.analyze(buffer: buffer, at: self.cumulativeFramePosition)
      self.cumulativeFramePosition += AVAudioFramePosition(buffer.frameLength)
      if let audioFile = self.audioFile {
        do {
          try audioFile.write(from: buffer)
        } catch {
          print("[AudioRecorder] Failed to write audio buffer: \(error)")
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
    isRecording = true
    isPaused = false
  }

  public func pauseRecording() {
    guard isRecording, let engine = audioEngine else { return }
    isPaused = true
    soundAnalyzer.stopAnalyzing()
    engine.stop()
    // Remove tap from the EQ node so the engine can be safely deallocated.
    // AVAudioEngine cannot be reliably restarted after stop() when a tap is installed.
    for node in engine.attachedNodes {
      if let eq = node as? AVAudioUnitEQ {
        eq.removeTap(onBus: 0)
        break
      }
    }
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

    let eq = AVAudioUnitEQ(numberOfBands: 1)
    let band = eq.bands[0]
    band.filterType = .bandPass
    band.frequency = 300
    band.bandwidth = 2.5
    band.gain = 0
    band.bypass = false
    engine.attach(eq)
    engine.connect(input, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    engine.mainMixerNode.volume = 0

    eq.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let db = self.calculateDB(from: buffer)
      let features = self.fftAnalyzer.analyze(buffer: buffer, sampleRate: format.sampleRate)
      self.soundAnalyzer.analyze(buffer: buffer, at: self.cumulativeFramePosition)
      self.cumulativeFramePosition += AVAudioFramePosition(buffer.frameLength)
      if let audioFile = self.audioFile {
        do {
          try audioFile.write(from: buffer)
        } catch {
          print("[AudioRecorder] Failed to write audio buffer: \(error)")
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

  public func stopRecording() {
    soundAnalyzer.stopAnalyzing()
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    audioFile = nil
    cumulativeFramePosition = 0
    isRecording = false
    isPaused = false
    currentDB = -160.0
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
}
