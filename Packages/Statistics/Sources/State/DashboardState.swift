import Foundation
import Models
import SleepCore

/// What the Statistics dashboard shows, derived from the stored sessions.
///
/// Pure: no SwiftUI, no SwiftData queries, no clock. The view passes its
/// `@Query` results and `Date()`; tests pass fixtures and a fixed `now`.
struct DashboardState {
  /// The most recent session by start date.
  let session: NightRecord
  /// Mean score of every session that started on the same calendar day as `session`.
  let dayScore: Int
  let daySessionCount: Int
  /// Up to 7 most recent sessions, newest first.
  let recentSessions: [NightRecord]
  /// `session` started yesterday relative to `now` (by start date, not end date).
  let isLastNight: Bool
  /// The week strip: 7 days ending on `now`'s day, with each day's snoring level.
  let week: [NightDashboard.WeekDay]
  /// SleepCore's dashboard (from summaries without events) and the time it was
  /// made for: what the shared `StatisticsDashboardContent` draws.
  let dashboard: NightDashboard
  let now: Date

  /// `nil` when there are no sessions. `sessions` may be in any order. The
  /// rules are SleepCore's `NightDashboard`; this maps its nights back to models.
  static func make(from sessions: [NightRecord], now: Date, calendar: Calendar = .current) -> DashboardState? {
    guard let dashboard = NightDashboard.make(from: sessions.summariesWithoutEvents, now: now, calendar: calendar) else {
      return nil
    }
    let byID = Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    guard let latest = byID[dashboard.latest.id] else { return nil }
    return DashboardState(
      session: latest,
      dayScore: dashboard.dayScore,
      daySessionCount: dashboard.dayNightCount,
      recentSessions: dashboard.recent.compactMap { byID[$0.id] },
      isLastNight: dashboard.isLastNight,
      week: dashboard.week(now: now, calendar: calendar),
      dashboard: dashboard,
      now: now)
  }
}
