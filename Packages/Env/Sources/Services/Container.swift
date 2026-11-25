public import AudioEngine
public import FactoryKit

/// Factory DI registrations for the session services. Config, Health and
/// Platform register their own (F27-T11); `tabCoordinator` is in Routing.
///
/// Every factory is typed as its service protocol (`any SessionManaging`, …) and
/// resolves the live `.shared` instance. Tests and previews override with the
/// fakes in `EnvTestSupport` (`register { FakeX() }`), scoped per test by
/// `FactoryTesting`'s `.container` trait.
///
/// `RouterPath` is not registered: it is per-tab SwiftUI environment state and
/// lives in the `Routing` package (docs/adr/0001-routing-package.md).
public extension Container {
  // MARK: - Singletons (@MainActor services)

  @MainActor var audioRecorder: Factory<any AudioRecording> { self { AudioRecorder.shared }.singleton }
  @MainActor var customMelodyStorage: Factory<any CustomMelodyStoring> { self { CustomMelodyStorage.shared }.singleton }
  @MainActor var pendingSessionStore: Factory<any PendingSessionStoring> { self { PendingSessionStore.shared }.singleton }
  @MainActor var recordingDelayManager: Factory<any RecordingDelayManaging> { self { RecordingDelayManager.shared }.singleton }
  @MainActor var sessionCheckpointStore: Factory<any SessionCheckpointStoring> { self { SessionCheckpointStore.shared }.singleton }
  @MainActor var sessionCommitter: Factory<any SessionCommitting> { self { SessionCommitter.shared }.singleton }
  @MainActor var sessionManager: Factory<any SessionManaging> { self { SessionManager.shared }.singleton }
  @MainActor var snoreInterrupterPlayer: Factory<any SnoreInterrupterPlaying> { self { SnoreInterrupterPlayer.shared }.singleton }
  @MainActor var soundAnalysisDetector: Factory<any SoundAnalysisDetecting> { self { SoundAnalysisDetector.shared }.singleton }

  // MARK: - Singletons (non-isolated services)

  var sessionRawLogWriter: Factory<any SessionRawLogWriting> { self { SessionRawLogWriter.shared }.singleton }
  var storageLimitEnforcer: Factory<any StorageLimitEnforcing> { self { StorageLimitEnforcer.shared }.singleton }
}

extension Container {
  // MARK: - Session composition (internal)

  /// Constructed — not `.shared`-aliased — because these types are internal
  /// to Env and owned exclusively by `SessionManager`, which performs the
  /// cross-wiring (`attach` / weak `recording`) in its init.
  @MainActor var sessionRecordingController: Factory<SessionRecordingController> { self { SessionRecordingController() }.singleton }
  @MainActor var realtimeDetectionTracker: Factory<RealtimeDetectionTracker> { self { RealtimeDetectionTracker() }.singleton }
}
