import Foundation
import Models

/// What the Statistics dashboard shows, derived from the stored sessions.
///
/// Pure: no SwiftUI, no SwiftData queries, no clock. The view passes its
/// `@Query` results and `Date()`; tests pass fixtures and a fixed `now`.
struct DashboardState {
  /// The most recent session by start date.
  let session: SleepSession
  /// Mean score of every session that started on the same calendar day as `session`.
  let dayScore: Int
  let daySessionCount: Int
  /// Up to 7 most recent sessions, newest first.
  let recentSessions: [SleepSession]
  /// `session` started yesterday relative to `now` (by start date, not end date).
  let isLastNight: Bool

  /// `nil` when there are no sessions. `sessions` may be in any order.
  static func make(from sessions: [SleepSession], now: Date, calendar: Calendar = .current) -> DashboardState? {
    let newestFirst = sessions.sorted { $0.startDate > $1.startDate }
    guard let latest = newestFirst.first else { return nil }

    let daySessions = newestFirst.filter { calendar.isDate($0.startDate, inSameDayAs: latest.startDate) }
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

    return DashboardState(
      session: latest,
      dayScore: daySessions.map(\.sleepScore).reduce(0, +) / daySessions.count,
      daySessionCount: daySessions.count,
      recentSessions: Array(newestFirst.prefix(7)),
      isLastNight: calendar.isDate(latest.startDate, inSameDayAs: yesterday))
  }
}
