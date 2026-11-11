import Foundation
import ModelsTestSupport
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
}
