import Config
import ConfigTestSupport
import Foundation
import HealthTestSupport
import Models
import ModelsTestSupport
import ServicesTestSupport
import SleepCore
import SwiftData
import Testing
@testable import Services

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
  private func finishedNight(endReason: Night.EndReason) -> NightRecord {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let session = NightRecord.fixture(start: start, hours: 7)
    session.endReason = endReason
    session.events = [
      .fixture(at: start.addingTimeInterval(3600)),
      .fixture(at: start.addingTimeInterval(7200), intensity: .loud),
    ]
    pending.setPending(sessionID: session.id, sessionAudioFilename: nil)
    pending.addFile("event_1.m4a")
    pending.addFile("event_2.m4a")
    var night = session.night
    night.end = start.addingTimeInterval(7 * 3600)
    checkpoint.write(night)
    return session
  }

  /// The regression: the low-battery path used to save without clearing the
  /// pending record or the checkpoint, so the next launch deleted the saved
  /// night's clips or offered to "recover" it again.
  @Test(arguments: [Night.EndReason.stopped, .lowBattery])
  func commitStoresTheNightAndClearsRecoveryState(endReason: Night.EndReason) async throws {
    let session = finishedNight(endReason: endReason)

    try await (makeCommitter().commit(session, in: store.context)).value

    let saved = try store.context.fetch(FetchDescriptor<NightRecord>())
    #expect(saved.map(\.id) == [session.id])
    #expect(try store.context.fetchCount(FetchDescriptor<NightEventRecord>()) == 2)
    #expect(pending.pendingSessionID == nil)
    #expect(pending.files.isEmpty)
    #expect(pending.cleanupCount == 0, "Clearing the record must not delete the saved night's files")
    #expect(checkpoint.loadIfPresent() == nil)
  }

  @Test func commitCachesTheScoreWithTheCurrentFormula() async throws {
    let session = finishedNight(endReason: .stopped)

    try await (makeCommitter().commit(session, in: store.context)).value

    #expect(session.hasSummary)
    #expect(session.scoreVersion == SleepScore.cacheVersion(for: appConfig.sleepScoreConfig))
    #expect(session.score == session.night.summary(using: appConfig.sleepScoreConfig).score)
  }

  @Test(arguments: [true, false])
  func followUpsEnforceLimitsAndSyncOnlyWhenEnabled(syncToHealthKit: Bool) async throws {
    preferences.syncToHealthKit = syncToHealthKit
    let session = finishedNight(endReason: .stopped)

    try await (makeCommitter().commit(session, in: store.context)).value

    #expect(enforcer.enforceCount == 1)
    #expect(healthKit.syncedSessionIDs == (syncToHealthKit ? [session.id] : []))
  }
}
