import AudioEngine
import FactoryKit
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

/// Public entry point for sleep-session recording. A thin facade that
/// forwards to two focused components:
/// - `SessionRecordingController` — session lifecycle, audio engine, files
/// - `RealtimeDetectionTracker` — snore/speech detection, event tracking
///
/// The public API is unchanged from the original monolith; observation works
/// through forwarding computed properties (both components are `@Observable`).
@MainActor
@Observable
public final class SessionManager: SessionManaging {
  public static let shared = SessionManager()

  // Resolved from the container in init rather than `@Injected`: the
  // `@Observable` macro and `@Injected` both synthesize underscore backing
  // storage, which collides on the same property name.
  private let recording: SessionRecordingController
  private let detection: RealtimeDetectionTracker

  public init() {
    let recording = Container.shared.sessionRecordingController()
    let detection = Container.shared.realtimeDetectionTracker()
    self.recording = recording
    self.detection = detection
    recording.attach(detection: detection)
    detection.recording = recording
  }

  // MARK: - Recording state

  public var currentSession: SleepSession? { recording.currentSession }
  public var isRecording: Bool { recording.isRecording }
  public var completedSession: SleepSession? {
    get { recording.completedSession }
    set { recording.completedSession = newValue }
  }

  public var isProcessingSession: Bool { recording.isProcessingSession }
  public var isLiveSessionVisible: Bool {
    get { recording.isLiveSessionVisible }
    set { recording.isLiveSessionVisible = newValue }
  }

  // MARK: - Real-time detection state (UI observation)

  public var currentDB: Float { detection.currentDB }
  public var currentDetectionState: DetectionState { detection.currentDetectionState }
  public var currentSpeechDetected: Bool { detection.currentSpeechDetected }
  public var eventsCount: Int { detection.eventsCount }

  // MARK: - Lifecycle

  public func startSession() throws {
    try recording.startSession()
  }

  public func stopSession() async -> SleepSession? {
    await recording.stopSession()
  }

  public func discardCompletedSession() {
    recording.discardCompletedSession()
  }

  public func stopAndDiscardSession() {
    recording.stopAndDiscardSession()
  }

  public func forceSaveDueToLowBattery() {
    recording.forceSaveDueToLowBattery()
  }

  // MARK: - Real-time processing

  public func processAudioLevel(db: Float) {
    detection.processAudioLevel(db: db)
  }

  public func processAudioLevel(db: Float, peakDB: Float? = nil, spectralScore: Float = 0, snoreConfidence: Float = 0, speechConfidence: Float = 0) {
    detection.processAudioLevel(
      db: db,
      peakDB: peakDB,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      speechConfidence: speechConfidence)
  }
}
