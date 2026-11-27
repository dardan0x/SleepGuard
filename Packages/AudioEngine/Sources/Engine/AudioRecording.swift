public import Foundation
public import Observation

/// Microphone capture: levels, per-event files, pause/resume, warm-up.
/// Fake: `FakeAudioRecorder` (ServicesTestSupport).
@MainActor
public protocol AudioRecording: AnyObject, Observable {
  var isRecording: Bool { get }
  var isPaused: Bool { get }
  var isWarmedUp: Bool { get }
  var currentDB: Float { get }
  var currentPeakDB: Float { get }
  var spectralScore: Float { get }
  /// The sound classifier's latest snore and speech confidences, 0...1.
  var snoreConfidence: Float { get }
  var speechConfidence: Float { get }
  var hasPermission: Bool { get }
  var currentEventID: UUID? { get }
  var onLevels: (@MainActor (Date) -> Void)? { get set }
  var onCaptureInterruption: (@MainActor (_ interrupted: Bool, _ at: Date) -> Void)? { get set }
  func checkPermission()
  func requestPermission() async -> Bool
  /// With `rawAudioFileName`, the whole night is also kept as that file in the
  /// clips folder, and the spectral score is computed.
  func startRecording(rawAudioFileName: String?) throws
  func pauseRecording()
  func resumeRecording()
  /// Writes the microphone into the event's clip (`<id>.caf` in the clips folder).
  func startEventFile(eventID: UUID) throws
  /// Closes the event's clip and keeps it; its URL, or `nil` when none was open.
  @discardableResult
  func finalizeEventFile() -> URL?
  /// Closes the event's clip and deletes it.
  func discardEventFile()
  func stopRecording()
  func startWarmup() throws
  func stopWarmup()
}
