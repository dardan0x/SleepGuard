import Foundation
import ModelsTestSupport
import SleepCore
import Testing
@testable import Models

/// The versioned score cache: one writer (`refreshCachedScore`) and a launch
/// pass that recomputes sessions scored by another formula or config.
@MainActor
struct SleepScoreCacheTests {
  private let store: TestStore
  private let start = TestCalendar.date(day: 1, hour: 23)

  init() throws {
    store = try TestStore()
  }

  /// 8 h night, 48 min light snoring → 82 with the default config.
  private func night(day: Int = 0) throws -> SleepSession {
    let start = start.addingTimeInterval(Double(day) * 86400)
    return try store.insert(
      .fixture(start: start),
      events: [.fixture(at: start.addingTimeInterval(3600), duration: 2880, intensity: .light)])
  }

  /// Simulates a value cached by an older formula.
  private func cache(_ session: SleepSession, score: Int, version: String) {
    session.hasCachedScore = true
    session.cachedSleepScore = score
    session.cachedSnoringDuration = 1
    session.cachedScoreVersion = version
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

    session.refreshCachedScore(using: .default)

    #expect(session.hasCachedScore)
    #expect(session.cachedSleepScore == 82)
    // Recomputed from events, not the stale cached snoring duration.
    #expect(session.cachedSnoringDuration == 2880)
    #expect(session.cachedScoreVersion == SleepScore.cacheVersion(for: .default))
  }

  // MARK: - Launch pass

  @Test func stalePassRecomputesOnlyStaleFinishedSessions() throws {
    let current = try night(day: 0)
    let stale = try night(day: 1)
    let uncached = try night(day: 2)
    let unfinished = try store.insert(SleepSession(startDate: start.addingTimeInterval(3 * 86400)))
    cache(current, score: 42, version: SleepScore.cacheVersion(for: .default))
    cache(stale, score: 42, version: "0-old")
    try store.context.save()

    let refreshed = try SleepSession.refreshStaleCachedScores(in: store.context, config: .default)

    #expect(refreshed == 2)
    #expect(current.cachedSleepScore == 42)
    #expect(stale.cachedSleepScore == 82)
    #expect(uncached.hasCachedScore && uncached.cachedSleepScore == 82)
    #expect(!unfinished.hasCachedScore)
  }

  @Test func stalePassIsANoOpOnceCurrent() throws {
    _ = try night()
    try SleepSession.refreshStaleCachedScores(in: store.context, config: .default)

    #expect(try SleepSession.refreshStaleCachedScores(in: store.context, config: .default) == 0)
  }

  @Test func configChangeMakesEverySessionStale() throws {
    let session = try night()
    try SleepSession.refreshStaleCachedScores(in: store.context, config: .default)

    let stricter = SleepScoreConfig(lightIntensityMultiplier: 20)
    #expect(try SleepSession.refreshStaleCachedScores(in: store.context, config: stricter) == 1)
    // 10% × 0.85 = 8; light 1 × 20 = 20 → 72
    #expect(session.cachedSleepScore == 72)
  }
}
