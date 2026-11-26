import Foundation
import ModelsTestSupport
import SleepCore
import SleepStore
import SwiftData
import Testing
@testable import Models

/// The versioned score cache: one writer (`refreshSummary(using:)`) and a launch
/// pass that recomputes sessions scored by another formula or config.
@MainActor
struct SleepScoreCacheTests {
  private let store: TestStore
  private let start = TestCalendar.date(day: 1, hour: 23)

  init() throws {
    store = try TestStore()
  }

  /// 8 h night, 48 min light snoring → 82 with the default config.
  private func night(day: Int = 0) throws -> NightRecord {
    let start = start.addingTimeInterval(Double(day) * 86400)
    return try store.insert(
      .fixture(start: start),
      events: [.fixture(at: start.addingTimeInterval(3600), duration: 2880, intensity: .light)])
  }

  /// Simulates a value cached by an older formula.
  private func cache(_ session: NightRecord, score: Int, version: String) {
    session.scoreVersion = "cached"
    session.score = score
    session.snoringDuration = 1
    session.scoreVersion = version
  }

  // MARK: - Version

  @Test func versionIsStableForTheSameConfig() {
    #expect(SleepScore.cacheVersion(for: .default) == SleepScore.cacheVersion(for: SleepScoreConfig()))
    #expect(SleepScore.cacheVersion(for: .default).hasPrefix("\(SleepScore.formulaVersion)-"))
  }

  @Test func versionChangesWithAnyCoefficient() {
    let tweaked = SleepScoreConfig(snoringMultiplier: 0.7)
    #expect(SleepScore.cacheVersion(for: tweaked) != SleepScore.cacheVersion(for: .default))
  }

  // MARK: - Owner

  @Test func refreshWritesEveryCachedField() throws {
    let session = try night()
    cache(session, score: 42, version: "0-old")

    session.refreshSummary(using: .default)

    #expect(session.hasSummary)
    #expect(session.score == 82)
    // Recomputed from events, not the stale cached snoring duration.
    #expect(session.snoringDuration == 2880)
    #expect(session.scoreVersion == SleepScore.cacheVersion(for: .default))
  }

  // MARK: - Launch pass

  @Test func stalePassRecomputesOnlyStaleNights() async throws {
    let current = try night(day: 0)
    let stale = try night(day: 1)
    let uncached = try night(day: 2)
    cache(current, score: 42, version: SleepScore.cacheVersion(for: .default))
    cache(stale, score: 42, version: "0-old")
    try store.context.save()

    let refreshed = try await NightRecord.refreshStaleSummaries(in: store.context, config: .default)

    #expect(refreshed == 2)
    #expect(current.score == 42)
    #expect(stale.score == 82)
    #expect(uncached.hasSummary && uncached.score == 82)
  }

  @Test func stalePassIsANoOpOnceCurrent() async throws {
    _ = try night()
    try await NightRecord.refreshStaleSummaries(in: store.context, config: .default)

    #expect(try await NightRecord.refreshStaleSummaries(in: store.context, config: .default) == 0)
  }

  @Test func configChangeMakesEverySessionStale() async throws {
    let session = try night()
    try await NightRecord.refreshStaleSummaries(in: store.context, config: .default)

    let stricter = SleepScoreConfig(lightIntensityMultiplier: 20)
    #expect(try await NightRecord.refreshStaleSummaries(in: store.context, config: stricter) == 1)
    // 10% × 0.85 = 8; light 1 × 20 = 20 → 72
    #expect(session.score == 72)
  }

  @Test func stalePassWorksThroughLongHistoriesInBatches() async throws {
    for day in 0..<120 {
      try cache(night(day: day), score: 42, version: "0-old")
    }
    try store.context.save()

    #expect(try await NightRecord.refreshStaleSummaries(in: store.context, config: .default, batchSize: 50) == 120)
    #expect(try await NightRecord.refreshStaleSummaries(in: store.context, config: .default) == 0)
  }
}
