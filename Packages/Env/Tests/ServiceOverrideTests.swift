import AudioEngine
import EnvTestSupport
import FactoryKit
import FactoryTesting
import Foundation
import Models
import Testing
@testable import Env

/// Every registered service can be replaced through the container, which is
/// what views (`@Injected`) and state owners (`Container.shared.x()`) resolve.
/// `.container` scopes each test's registrations, so they run in parallel.
@MainActor
@Suite(.container)
struct ServiceOverrideTests {
  @Test func defaultsResolveTheLiveSingletons() {
    #expect(Container.shared.userPreferences() === UserPreferences.shared)
    #expect(Container.shared.sessionManager() === SessionManager.shared)
    #expect(Container.shared.audioRecorder() === AudioRecorder.shared)
  }

  @Test func sessionManagerOverride() throws {
    let fake = FakeSessionManager()
    Container.shared.sessionManager.register { fake }

    let resolved = Container.shared.sessionManager()
    try resolved.startSession()

    #expect(resolved === fake)
    #expect(fake.startCount == 1 && fake.isRecording)
  }

  @Test func audioRecorderOverride() throws {
    let fake = FakeAudioRecorder()
    Container.shared.audioRecorder.register { fake }

    try Container.shared.audioRecorder().startRecording(audioFileURL: nil)

    #expect(fake.isRecording)
  }

  @Test func soundAnalysisOverride() {
    let fake = FakeSoundAnalysisDetector()
    fake.snoreConfidence = 0.8
    Container.shared.soundAnalysisDetector.register { fake }

    #expect(Container.shared.soundAnalysisDetector().snoreConfidence == 0.8)
  }

  @Test func hapticOverrideRecordsCalls() {
    let fake = FakeHapticManager()
    Container.shared.hapticManager.register { fake }

    Container.shared.hapticManager().tap()

    #expect(fake.calls == ["tap"])
  }

  @Test func interrupterOverrideRespectsSessionMute() {
    let fake = FakeSnoreInterrupterPlayer()
    Container.shared.snoreInterrupterPlayer.register { fake }
    let player = Container.shared.snoreInterrupterPlayer()

    player.muteForSession()
    player.playIfNeeded()

    #expect(fake.playRequests == 1 && !fake.isPlaying)
  }

  @Test func storeOverrides() {
    let pending = FakePendingSessionStore()
    let checkpoints = FakeSessionCheckpointStore()
    let melodies = FakeCustomMelodyStorage()
    Container.shared.pendingSessionStore.register { pending }
    Container.shared.sessionCheckpointStore.register { checkpoints }
    Container.shared.customMelodyStorage.register { melodies }

    Container.shared.pendingSessionStore().addFile("a.m4a")
    Container.shared.sessionCheckpointStore().clear()
    let saved = Container.shared.customMelodyStorage().saveRecording(name: "Mine", from: URL(fileURLWithPath: "/tmp/x.m4a"))

    #expect(pending.files == ["a.m4a"])
    #expect(checkpoints.loadIfPresent() == nil)
    #expect(saved.map { melodies.melody(id: $0.id) != nil } == true)
  }

  @Test func coordinationOverrides() {
    let tabs = FakeTabCoordinator()
    let delay = FakeRecordingDelayManager()
    Container.shared.tabCoordinator.register { tabs }
    Container.shared.recordingDelayManager.register { delay }

    Container.shared.tabCoordinator().selectTab(.statistics)
    Container.shared.recordingDelayManager().startDelay(minutes: 2)

    #expect(tabs.resetSignal?.tab == .statistics) // already selected → pop to root
    #expect(delay.isActive && delay.remainingTimeString == "2:00")
  }

  @Test func permissionAndDeviceOverrides() async {
    let notifications = FakeNotificationPermissionManager(grantsAuthorization: false)
    let watch = FakeWatchConnectivityManager(isWatchReachable: true)
    let health = FakeHealthKitSync()
    Container.shared.notificationPermissionManager.register { notifications }
    Container.shared.watchConnectivityManager.register { watch }
    Container.shared.healthKitSync.register { health }

    let granted = await Container.shared.notificationPermissionManager().requestAuthorization()
    let healthGranted = await Container.shared.healthKitSync().requestAuthorization()

    #expect(!granted && notifications.authorizationStatus == .denied)
    #expect(Container.shared.watchConnectivityManager().isWatchReachable)
    #expect(healthGranted && health.authorizationRequests == 1)
  }

  @Test func nonisolatedServiceOverrides() async {
    let writer = FakeSessionRawLogWriter()
    Container.shared.sessionRawLogWriter.register { writer }
    Container.shared.storageLimitEnforcer.register { FakeStorageLimitEnforcer() }

    await Container.shared.sessionRawLogWriter().start(
      sessionID: UUID(),
      metadata: RawLogMetadata(sessionStart: .now, detectionSensitivity: "medium", detectSleepTalking: false, snoreInterrupterMode: "never"))

    #expect(await writer.metadata?.detectionSensitivity == "medium")
    #expect(Container.shared.storageLimitEnforcer() is FakeStorageLimitEnforcer)
  }
}

/// `UserPreferences` / `AppConfig` doubles: the real types on isolated suites.
@MainActor
struct IsolatedStoreTests {
  @Test func preferencesDoNotLeakBetweenInstances() {
    let a = UserPreferences.isolated()
    let b = UserPreferences.isolated()

    a.recordingDelayMinutes = 15

    #expect(a.recordingDelayMinutes == 15)
    #expect(b.recordingDelayMinutes == 0)
  }

  @Test func appConfigPersistsAppliedValuesToItsStore() {
    let defaults = UserDefaults.isolated()
    AppConfig(defaults: defaults).apply(
      flags: [FeatureFlag.snoreInterrupter.rawValue: false],
      tabs: [], learnTab: nil, updateGate: .none)

    // A new instance on the same store reloads the cached remote values.
    #expect(!AppConfig(defaults: defaults).isEnabled(.snoreInterrupter))
    #expect(AppConfig.isolated().isEnabled(.snoreInterrupter))
  }
}
