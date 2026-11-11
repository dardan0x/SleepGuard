import Foundation
import Models
import Observation

/// Microphone capture: levels, per-event files, pause/resume, warm-up.
/// Fake: `FakeAudioRecorder` (EnvTestSupport).
@MainActor
public protocol AudioRecording: AnyObject, Observable {
  var isRecording: Bool { get }
  var isPaused: Bool { get }
  var isWarmedUp: Bool { get }
  var currentDB: Float { get }
  var currentPeakDB: Float { get }
  var spectralScore: Float { get }
  var hasPermission: Bool { get }
  var isWritingToFile: Bool { get }
  var currentEventID: UUID? { get }
  func checkPermission()
  func requestPermission() async -> Bool
  func startRecording(audioFileURL: URL?) throws
  func pauseRecording()
  func resumeRecording() throws
  func startEventFile(eventID: UUID, url: URL) throws
  @discardableResult
  func finalizeEventFile() -> URL?
  func stopRecording()
  func startWarmup() throws
  func stopWarmup()
}
