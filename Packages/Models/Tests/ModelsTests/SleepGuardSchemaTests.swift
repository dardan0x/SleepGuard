import Foundation
import ModelsTestSupport
import SleepCore
import SwiftData
import Testing
@testable import Models

@MainActor
struct SleepGuardSchemaTests {
  @Test func v1ListsEveryPersistedModel() {
    let entities = Set(SleepGuardSchema.schema.entities.map(\.name))
    #expect(entities == ["SleepSession", "SnoreEvent", "UserProfile", "LifestyleLog"])
  }

  /// Existing installs have a store written without a migration plan. Opening it
  /// through the plan must keep every row, or the app's delete-and-retry fallback
  /// would wipe user data on first launch.
  @Test func preV1OnDiskStoreOpensThroughTheMigrationPlanIntact() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SleepGuardSchemaTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("legacy.store")

    let sessionID: UUID
    do {
      let legacySchema = Schema([SleepSession.self, SnoreEvent.self, UserProfile.self, LifestyleLog.self])
      let legacy = try ModelContainer(
        for: legacySchema,
        configurations: [ModelConfiguration(schema: legacySchema, url: url)])
      let start = Date(timeIntervalSince1970: 1_000_000)
      let session = SleepSession(startDate: start, endDate: start.addingTimeInterval(8 * 3600))
      legacy.mainContext.insert(session)
      let event = SnoreEvent(
        timestamp: start.addingTimeInterval(60), intensity: .loud, averageDB: -30, peakDB: -20, duration: 5)
      legacy.mainContext.insert(event)
      session.events = [event]
      try legacy.mainContext.save()
      sessionID = session.id
    }

    let versioned = try SleepGuardSchema.container(ModelConfiguration(schema: SleepGuardSchema.schema, url: url))
    let sessions = try versioned.mainContext.fetch(FetchDescriptor<SleepSession>())
    #expect(sessions.map(\.id) == [sessionID])
    #expect(sessions.first?.events?.count == 1)
  }

  /// `Fixtures/premove-v1.store` was written when the value types stored inside
  /// the models (`RecordingGap`, `SleepStageSegment`, `SnoreBurst`, the enums)
  /// were declared in `Models`. They now live in `SleepCore`. An existing
  /// install's store must still open and decode every one of them.
  @Test func storeWrittenBeforeTheValueTypesMovedToSleepCoreStillOpens() throws {
    let fixture = try #require(
      Bundle.module.url(forResource: "premove-v1", withExtension: "store", subdirectory: "Fixtures"))
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SleepGuardSchemaTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("premove.store")
    try FileManager.default.copyItem(at: fixture, to: url)

    let container = try SleepGuardSchema.container(ModelConfiguration(schema: SleepGuardSchema.schema, url: url))
    let session = try #require(try container.mainContext.fetch(FetchDescriptor<SleepSession>()).first)

    #expect(session.recordingGaps?.map(\.duration) == [30, 20])
    #expect(session.recordingGaps?.map(\.snoringResumed) == [true, false])
    #expect(session.sleepStageSegments?.map(\.stage) == [.deep, .rem, .awake])
    let events = (session.events ?? []).sorted { $0.timestamp < $1.timestamp }
    #expect(events.map(\.category) == [.snoring, .sleepTalking])
    #expect(events.map(\.intensity) == [.loud, .quiet])
    #expect(events.first?.bursts == [SnoreBurst(startOffset: 0, endOffset: 4), SnoreBurst(startOffset: 6, endOffset: 9)])
    // The cached values written before the move, and the same score recomputed now.
    #expect(session.cachedSleepScore == 78)
    #expect(session.cachedSnoringDuration == 39)
    #expect(session.cachedScoreVersion == SleepScore.cacheVersion(for: .default))
    #expect(session.sleepScore(using: .default) == 78)
  }
}
