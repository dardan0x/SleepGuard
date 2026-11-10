import AudioEngine
import FactoryKit

/// Factory DI registrations for SleepGuard's shared services.
///
/// Singleton factories resolve the existing `.shared` instances, so behavior is
/// identical to direct singleton access while gaining container-based resolution,
/// preview mocking (`register { ... }`), and per-test overrides.
///
/// `RouterPath` is not registered: it is per-tab SwiftUI environment state and
/// lives in the `Routing` package (docs/adr/0001-routing-package.md).
public extension Container {
  // MARK: - Singletons (@MainActor services)

  @MainActor var appConfig: Factory<AppConfig> { self { AppConfig.shared }.singleton }
  @MainActor var audioRecorder: Factory<AudioRecorder> { self { AudioRecorder.shared }.singleton }
  @MainActor var customMelodyStorage: Factory<CustomMelodyStorage> { self { CustomMelodyStorage.shared }.singleton }
  @MainActor var healthKitSync: Factory<any HealthKitSyncing> { self { HealthKitSync.shared }.singleton }
  @MainActor var hapticManager: Factory<HapticManager> { self { HapticManager.shared }.singleton }
  @MainActor var notificationPermissionManager: Factory<NotificationPermissionManager> { self { NotificationPermissionManager.shared }.singleton }
  @MainActor var pendingSessionStore: Factory<PendingSessionStore> { self { PendingSessionStore.shared }.singleton }
  @MainActor var recordingDelayManager: Factory<RecordingDelayManager> { self { RecordingDelayManager.shared }.singleton }
  @MainActor var sessionCheckpointStore: Factory<SessionCheckpointStore> { self { SessionCheckpointStore.shared }.singleton }
  @MainActor var sessionManager: Factory<SessionManager> { self { SessionManager.shared }.singleton }
  @MainActor var snoreInterrupterPlayer: Factory<SnoreInterrupterPlayer> { self { SnoreInterrupterPlayer.shared }.singleton }
  @MainActor var soundAnalysisDetector: Factory<SoundAnalysisDetector> { self { SoundAnalysisDetector.shared }.singleton }
  @MainActor var userPreferences: Factory<UserPreferences> { self { UserPreferences.shared }.singleton }
  @MainActor var watchConnectivityManager: Factory<WatchConnectivityManager> { self { WatchConnectivityManager.shared }.singleton }

  // MARK: - Singletons (non-isolated services)

  var sessionRawLogWriter: Factory<SessionRawLogWriter> { self { SessionRawLogWriter.shared }.singleton }
  var storageLimitEnforcer: Factory<StorageLimitEnforcer> { self { StorageLimitEnforcer.shared }.singleton }
  @MainActor var tabCoordinator: Factory<TabCoordinator> { self { TabCoordinator.shared }.singleton }
}

extension Container {
  // MARK: - Session composition (internal)

  /// Constructed — not `.shared`-aliased — because these types are internal
  /// to Env and owned exclusively by `SessionManager`, which performs the
  /// cross-wiring (`attach` / weak `recording`) in its private init.
  @MainActor var sessionRecordingController: Factory<SessionRecordingController> { self { SessionRecordingController() }.singleton }
  @MainActor var realtimeDetectionTracker: Factory<RealtimeDetectionTracker> { self { RealtimeDetectionTracker() }.singleton }
}
