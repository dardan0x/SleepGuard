import AudioEngine
import FactoryKit

/// Factory DI registrations for SleepGuard's shared services.
///
/// Every factory is typed as its service protocol (`any HealthKitSyncing`, …) and
/// resolves the live `.shared` instance. Tests and previews override with the
/// fakes in `EnvTestSupport` (`register { FakeX() }`), scoped per test by
/// `FactoryTesting`'s `.container` trait.
///
/// `RouterPath` is not registered: it is per-tab SwiftUI environment state and
/// lives in the `Routing` package (docs/adr/0001-routing-package.md).
public extension Container {
  // MARK: - Singletons (@MainActor services)

  @MainActor var appConfig: Factory<any AppConfigProviding> { self { AppConfig.shared }.singleton }
  @MainActor var audioRecorder: Factory<any AudioRecording> { self { AudioRecorder.shared }.singleton }
  @MainActor var customMelodyStorage: Factory<any CustomMelodyStoring> { self { CustomMelodyStorage.shared }.singleton }
  @MainActor var healthKitSync: Factory<any HealthKitSyncing> { self { HealthKitSync.shared }.singleton }
  @MainActor var hapticManager: Factory<any HapticFeedbackProviding> { self { HapticManager.shared }.singleton }
  @MainActor var notificationPermissionManager: Factory<any NotificationPermissionManaging> { self { NotificationPermissionManager.shared }.singleton }
  @MainActor var pendingSessionStore: Factory<any PendingSessionStoring> { self { PendingSessionStore.shared }.singleton }
  @MainActor var recordingDelayManager: Factory<any RecordingDelayManaging> { self { RecordingDelayManager.shared }.singleton }
  @MainActor var sessionCheckpointStore: Factory<any SessionCheckpointStoring> { self { SessionCheckpointStore.shared }.singleton }
  @MainActor var sessionCommitter: Factory<any SessionCommitting> { self { SessionCommitter.shared }.singleton }
  @MainActor var sessionManager: Factory<any SessionManaging> { self { SessionManager.shared }.singleton }
  @MainActor var snoreInterrupterPlayer: Factory<any SnoreInterrupterPlaying> { self { SnoreInterrupterPlayer.shared }.singleton }
  @MainActor var soundAnalysisDetector: Factory<any SoundAnalysisDetecting> { self { SoundAnalysisDetector.shared }.singleton }
  @MainActor var userPreferences: Factory<any UserPreferencesStoring> { self { UserPreferences.shared }.singleton }
  @MainActor var watchConnectivityManager: Factory<any WatchConnectivityManaging> { self { WatchConnectivityManager.shared }.singleton }

  // MARK: - Singletons (non-isolated services)

  var sessionRawLogWriter: Factory<any SessionRawLogWriting> { self { SessionRawLogWriter.shared }.singleton }
  var storageLimitEnforcer: Factory<any StorageLimitEnforcing> { self { StorageLimitEnforcer.shared }.singleton }
  @MainActor var tabCoordinator: Factory<any TabCoordinating> { self { TabCoordinator.shared }.singleton }
}

extension Container {
  // MARK: - Session composition (internal)

  /// Constructed — not `.shared`-aliased — because these types are internal
  /// to Env and owned exclusively by `SessionManager`, which performs the
  /// cross-wiring (`attach` / weak `recording`) in its init.
  @MainActor var sessionRecordingController: Factory<SessionRecordingController> { self { SessionRecordingController() }.singleton }
  @MainActor var realtimeDetectionTracker: Factory<RealtimeDetectionTracker> { self { RealtimeDetectionTracker() }.singleton }
}
