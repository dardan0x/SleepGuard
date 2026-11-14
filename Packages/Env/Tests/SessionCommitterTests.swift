import EnvTestSupport
import Foundation
import Models
import ModelsTestSupport
import SleepCore
import SwiftData
import Testing
@testable import Env

/// Saving a finished night has one owner (F23-T1). Both the summary sheet and
/// the low-battery force-save go through `SessionCommitter`, so they can't
/// drift apart again.
@MainActor
struct SessionCommitterTests {
  private let store: TestStore
  private let preferences = UserPreferences.isolated()
  private let appConfig = AppConfig.isolated()
  private let pending = FakePendingSessionStore()
  private let checkpoint = FakeSessionCheckpointStore()
  private let enforcer = FakeStorageLimitEnforcer()
  private let healthKit = FakeHealthKitSync(isAuthorized: true)

  init() throws {
    store = try TestStore()
  }

  private func makeCommitter() -> SessionCommitter {
    SessionCommitter(
      preferences: preferences,
      appConfig: appConfig,
      pendingSessionStore: pending,
      checkpointStore: checkpoint,
      storageLimitEnforcer: enforcer,
      healthKitSync: healthKit)
  }

  /// A finished, not-yet-inserted night as `SessionRecordingController` hands
  /// it over: events attached, clips registered as pending, a checkpoint on disk.
  private func finishedNight(terminationReason: String?) -> SleepSession {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let session = SleepSession.fixture(start: start, hours: 7)
    session.terminationReason = terminationReason
    session.events = [
      .fixture(at: start.addingTimeInterval(3600)),
      .fixture(at: start.addingTimeInterval(7200), intensity: .loud),
    ]
    pending.setPending(sessionID: session.id, sessionAudioFilename: nil)
    pending.addFile("event_1.m4a")
    pending.addFile("event_2.m4a")
    checkpoint.write(SessionRecoverySnapshot(from: session, checkpointDate: start.addingTimeInterval(7 * 3600)))
    return session
  }

  /// The regression: the low-battery path used to save without clearing the
  /// pending record or the checkpoint, so the next launch deleted the saved
  /// night's clips or offered to "recover" it again.
  @Test(arguments: [nil, "low_battery"])
  func commitStoresTheNightAndClearsRecoveryState(terminationReason: String?) async throws {
    let session = finishedNight(terminationReason: terminationReason)

    try await (makeCommitter().commit(session, in: store.context)).value

    let saved = try store.context.fetch(FetchDescriptor<SleepSession>())
    #expect(saved.map(\.id) == [session.id])
    #expect(try store.context.fetchCount(FetchDescriptor<SnoreEvent>()) == 2)
    #expect(pending.pendingSessionID == nil)
    #expect(pending.files.isEmpty)
    #expect(pending.cleanupCount == 0, "Clearing the record must not delete the saved night's files")
    #expect(checkpoint.loadIfPresent() == nil)
  }

  @Test func commitCachesTheScoreWithTheCurrentFormula() async throws {
    let session = finishedNight(terminationReason: nil)

    try await (makeCommitter().commit(session, in: store.context)).value

    #expect(session.hasCachedScore)
    #expect(session.cachedScoreVersion == SleepScore.cacheVersion(for: appConfig.sleepScoreConfig))
    #expect(session.cachedSleepScore == SleepScore.compute(session.sleepInputs, config: appConfig.sleepScoreConfig))
  }

  @Test(arguments: [true, false])
  func followUpsEnforceLimitsAndSyncOnlyWhenEnabled(syncToHealthKit: Bool) async throws {
    preferences.syncToHealthKit = syncToHealthKit
    let session = finishedNight(terminationReason: nil)

    try await (makeCommitter().commit(session, in: store.context)).value

    #expect(enforcer.enforceCount == 1)
    #expect(healthKit.syncedSessionIDs == (syncToHealthKit ? [session.id] : []))
  }
}
