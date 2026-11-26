import AudioEngine
public import Foundation
public import Models
public import SleepCore
public import SleepStore

/// Facade over the live recording session that features observe.
/// Fake: `FakeSessionManager`.
@MainActor
public protocol SessionManaging: AnyObject, Observable {
  var currentSession: NightRecord? { get }
  var isRecording: Bool { get }
  var completedSession: NightRecord? { get set }
  var isProcessingSession: Bool { get }
  var isLiveSessionVisible: Bool { get set }
  var currentDB: Float { get }
  var currentDetectionState: DetectionState { get }
  var currentSpeechDetected: Bool { get }
  var eventsCount: Int { get }
  func startSession() throws
  func stopSession() async -> NightRecord?
  func discardCompletedSession()
  func stopAndDiscardSession()
  func forceSaveDueToLowBattery()
  func processAudioLevel(db: Float)
  func processAudioLevel(db: Float, peakDB: Float?, spectralScore: Float, snoreConfidence: Float, speechConfidence: Float)
}
