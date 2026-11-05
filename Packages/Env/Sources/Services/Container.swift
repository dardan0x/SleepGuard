import AudioEngine
import FactoryKit

/// Factory DI registrations for SleepGuard's shared services.
///
/// Singleton factories resolve the existing `.shared` instances, so behavior is
/// identical to direct singleton access while gaining container-based resolution,
/// preview mocking (`register { ... }`), and per-test overrides.
///
/// `routerPath` intentionally keeps Factory's default `.unique` scope — each
/// injection site gets its own instance, matching per-tab / per-sheet usage.
public extension Container {
  // MARK: - Singletons (@MainActor services)

  @MainActor var appConfig: Factory<AppConfig> { self { AppConfig.shared }.singleton }
  @MainActor var audioRecorder: Factory<AudioRecorder> { self { AudioRecorder.shared }.singleton }
  @MainActor var customMelodyStorage: Factory<CustomMelodyStorage> { self { CustomMelodyStorage.shared }.singleton }
  @MainActor var healthKitSync: Factory<HealthKitSync> { self { HealthKitSync.shared }.singleton }
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

  // MARK: - Per-instance

  @MainActor var routerPath: Factory<RouterPath> { self { RouterPath() } }
}
