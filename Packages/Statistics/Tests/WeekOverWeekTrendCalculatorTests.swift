import Foundation
import Models
import ModelsTestSupport
import Testing
@testable import Statistics

/// "This week vs last week" on Last 7 Nights. A "week" is the 7 most recent
/// *recorded* days (not calendar weeks); the previous week is the next ≤ 7.
/// Uses `Calendar.current` like the calculator, at midday.
struct WeekOverWeekTrendCalculatorTests {
  private let today = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

  private func session(daysAgo: Int, score: Int) -> SleepSession {
    let session = SleepSession.fixture(start: Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!)
    session.hasCachedScore = true
    session.cachedSleepScore = score
    return session
  }

  /// `recent` scores for days 0…, then `previous` scores for the days after.
  private func sessions(recent: [Int], previous: [Int]) -> [SleepSession] {
    (recent + previous).enumerated().map { session(daysAgo: $0.offset, score: $0.element) }
  }

  @Test func noSessionsProducesNoTrend() {
    #expect(WeekOverWeekTrendCalculator.trend(for: []) == nil)
  }

  @Test func needsAtLeastEightRecordedDays() {
    #expect(WeekOverWeekTrendCalculator.trend(for: sessions(recent: Array(repeating: 80, count: 7), previous: [])) == nil)
    #expect(WeekOverWeekTrendCalculator.trend(for: sessions(recent: Array(repeating: 80, count: 7), previous: [70]))?.diff == 10)
  }

  @Test func betterWeekIsPositive() throws {
    let trend = try #require(WeekOverWeekTrendCalculator.trend(for: sessions(
      recent: Array(repeating: 85, count: 7), previous: Array(repeating: 80, count: 7))))
    #expect(trend.diff == 5)
    #expect(trend.isPositive)
  }

  @Test func worseWeekIsNegative() throws {
    let trend = try #require(WeekOverWeekTrendCalculator.trend(for: sessions(
      recent: Array(repeating: 70, count: 7), previous: Array(repeating: 80, count: 7))))
    #expect(trend.diff == -10)
    #expect(!trend.isPositive)
  }

  @Test func equalWeeksProduceNoTrend() {
    #expect(WeekOverWeekTrendCalculator.trend(for: sessions(
      recent: Array(repeating: 80, count: 7), previous: Array(repeating: 80, count: 7))) == nil)
  }

  @Test func sessionsOnTheSameDayAreAveragedFirst() {
    // Today has 60 and 100 → 80, so the recent week averages 80.
    let recent = [session(daysAgo: 0, score: 60), session(daysAgo: 0, score: 100)]
      + (1..<7).map { session(daysAgo: $0, score: 80) }
    #expect(WeekOverWeekTrendCalculator.trend(for: recent + [session(daysAgo: 7, score: 70)])?.diff == 10)
  }

  @Test func onlyFourteenRecordedDaysCount() {
    // A 15th, much older day with score 0 must not drag the previous week down.
    let trend = WeekOverWeekTrendCalculator.trend(for: sessions(
      recent: Array(repeating: 80, count: 7), previous: Array(repeating: 70, count: 7) + [0]))
    #expect(trend?.diff == 10)
  }

  @Test func daysWithoutRecordingsAreSkipped() {
    // 8 recorded days spread over a month still form two "weeks".
    let spread = (0..<8).map { session(daysAgo: $0 * 4, score: $0 < 7 ? 90 : 60) }
    #expect(WeekOverWeekTrendCalculator.trend(for: spread)?.diff == 30)
  }
}
