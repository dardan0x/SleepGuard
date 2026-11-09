import Foundation
import Models

struct Trend {
  /// Current week's average score minus the previous week's (never 0).
  let diff: Int
  var isPositive: Bool {
    diff > 0
  }
}

enum WeekOverWeekTrendCalculator {
  static func trend(for sessions: [SleepSession]) -> Trend? {
    let calendar = Calendar.current
    let allGroups = Dictionary(grouping: sessions) {
      calendar.startOfDay(for: $0.startDate)
    }

    let sortedDays = allGroups.map { date, daySessions in
      let avgScore = daySessions.map(\.sleepScore).reduce(0, +) / max(daySessions.count, 1)
      return (date: date, avgScore: avgScore)
    }.sorted { $0.date > $1.date }

    guard sortedDays.count >= 8 else { return nil }

    let currentWeek = sortedDays.prefix(7).map(\.avgScore)
    let previousWeek = sortedDays.dropFirst(7).prefix(7).map(\.avgScore)

    guard !currentWeek.isEmpty, !previousWeek.isEmpty else { return nil }

    let currentAvg = currentWeek.reduce(0, +) / currentWeek.count
    let previousAvg = previousWeek.reduce(0, +) / previousWeek.count
    let diff = currentAvg - previousAvg

    guard diff != 0 else { return nil }

    return Trend(diff: diff)
  }
}
