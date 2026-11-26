public import AudioEngine
public import AVFoundation
public import Foundation
public import Observation
public import SoundAnalysis

/// Scriptable `AudioRecording`; never opens the microphone.
@MainActor
@Observable
public final class FakeAudioRecorder: AudioRecording {
  public var isRecording = false
  public var isPaused = false
  public var isWarmedUp = false
  public var currentDB: Float = -160
  public var currentPeakDB: Float = -160
  public var spectralScore: Float = 0
  public var hasPermission: Bool
  public var isWritingToFile = false
  public private(set) var currentEventID: UUID?
  public var onLevels: (@MainActor (Date) -> Void)?
  public var onCaptureInterruption: (@MainActor (_ interrupted: Bool, _ at: Date) -> Void)?
  public var computesSpectrum = false

  public init(hasPermission: Bool = true) {
    self.hasPermission = hasPermission
  }

  public func checkPermission() {}
  public func requestPermission() async -> Bool { hasPermission }
  public func startRecording(audioFileURL _: URL?) throws { isRecording = true }
  public func pauseRecording() { isPaused = true }
  public func resumeRecording() throws { isPaused = false }

  public func startEventFile(eventID: UUID, url _: URL) throws {
    currentEventID = eventID
    isWritingToFile = true
  }

  public func finalizeEventFile() -> URL? {
    currentEventID = nil
    isWritingToFile = false
    return nil
  }

  public func stopRecording() { isRecording = false }
  public func startWarmup() throws { isWarmedUp = true }
  public func stopWarmup() { isWarmedUp = false }
}

/// Scriptable `SoundAnalysisDetecting`: set the confidences directly.
@MainActor
@Observable
public final class FakeSoundAnalysisDetector: SoundAnalysisDetecting {
  public var snoreConfidence: Float = 0
  public var speechConfidence: Float = 0
  public var isSnoringClassAvailable = true

  public init() {}

  public func startAnalyzing(format _: AVAudioFormat) -> SNAudioStreamAnalyzer? { nil }
  public func stopAnalyzing() {}
}
