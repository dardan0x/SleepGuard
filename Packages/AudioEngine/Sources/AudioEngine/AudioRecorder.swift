import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioRecorder {
  public static let shared = AudioRecorder()

  public var isRecording = false
  public var currentDB: Float = -160.0
  public var hasPermission = false

  private var audioEngine: AVAudioEngine?

  private init() {
    checkPermission()
  }

  public func checkPermission() {
    // TECH DEBT: Auto-grant on simulator because AVAudioSession permission
    // requests behave unreliably in the iOS Simulator (no mic hardware).
    // Remove this #if block when testing on physical devices becomes routine.
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
    // TECH DEBT: Same simulator bypass as checkPermission().
    // Revert to real permission flow once off simulator.
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

  public func startRecording() throws {
    guard hasPermission else { return }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
    try session.setActive(true)

    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)

    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let db = self.calculateDB(from: buffer)
      Task { @MainActor in
        self.currentDB = db
      }
    }

    try engine.start()
    audioEngine = engine
    isRecording = true
  }

  public func stopRecording() {
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    isRecording = false
    currentDB = -160.0

    try? AVAudioSession.sharedInstance().setActive(false)
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
