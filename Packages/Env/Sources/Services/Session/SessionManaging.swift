import AudioEngine
import Foundation
import Models

/// Facade over the live recording session that features observe.
/// Fake: `FakeSessionManager`.
@MainActor
public protocol SessionManaging: AnyObject, Observable {
  var currentSession: SleepSession? { get }
  var isRecording: Bool { get }
  var completedSession: SleepSession? { get set }
  var isProcessingSession: Bool { get }
  var isLiveSessionVisible: Bool { get set }
  var currentDB: Float { get }
  var currentDetectionState: DetectionState { get }
  var currentSpeechDetected: Bool { get }
  var eventsCount: Int { get }
  func startSession() throws
  func stopSession() async -> SleepSession?
  func discardCompletedSession()
  func stopAndDiscardSession()
  func forceSaveDueToLowBattery()
  func processAudioLevel(db: Float)
  func processAudioLevel(db: Float, peakDB: Float?, spectralScore: Float, snoreConfidence: Float, speechConfidence: Float)
}
