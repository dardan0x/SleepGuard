public import AudioEngine
public import Foundation
public import Observation

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
  public var snoreConfidence: Float = 0
  public var speechConfidence: Float = 0
  public var hasPermission: Bool
  public private(set) var currentEventID: UUID?
  public var onLevels: (@MainActor (Date) -> Void)?
  public var onCaptureInterruption: (@MainActor (_ interrupted: Bool, _ at: Date) -> Void)?

  public init(hasPermission: Bool = true) {
    self.hasPermission = hasPermission
  }

  public func checkPermission() {}
  public func requestPermission() async -> Bool { hasPermission }
  public func startRecording(rawAudioFileName _: String?) throws { isRecording = true }
  public func pauseRecording() { isPaused = true }
  public func resumeRecording() { isPaused = false }

  public func startEventFile(eventID: UUID) throws {
    currentEventID = eventID
  }

  public func finalizeEventFile() -> URL? {
    currentEventID = nil
    return nil
  }

  public func discardEventFile() {
    currentEventID = nil
  }

  public func stopRecording() { isRecording = false }
  public func startWarmup() throws { isWarmedUp = true }
  public func stopWarmup() { isWarmedUp = false }
}
