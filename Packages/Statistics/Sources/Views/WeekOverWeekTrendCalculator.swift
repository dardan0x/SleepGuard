import Foundation
import Models
import SleepCore

struct Trend {
  /// Current week's average score minus the previous week's (never 0).
  let diff: Int
  var isPositive: Bool {
    diff > 0
  }
}

/// The rule is SleepCore's `ScoreTrend.weekOverWeek`.
enum WeekOverWeekTrendCalculator {
  static func trend(for sessions: [SleepSession]) -> Trend? {
    ScoreTrend.weekOverWeek(sessions.summariesWithoutEvents).map { Trend(diff: $0.diff) }
  }
}
