import SwiftUI
import Models
import DesignSystem

struct CalendarMonthStatsView: View {
  let monthSessions: [SleepSession]
  @Environment(Theme.self) private var theme

  var body: some View {
    HStack(spacing: 8) {
      CalendarStatCard(
        icon: "moon.fill",
        label: "SESSIONS",
        value: "\(monthSessions.count)",
        theme: theme
      )
      CalendarStatCard(
        icon: "scope",
        label: "AVG SCORE",
        value: monthSessions.isEmpty ? "—" : "\(avgScore)",
        theme: theme
      )
      CalendarStatCard(
        icon: "speaker.wave.3.fill",
        label: "LOUD NIGHTS",
        value: "\(loudNights)",
        theme: theme
      )
    }
  }

  private var avgScore: Int {
    guard !monthSessions.isEmpty else { return 0 }
    return monthSessions.reduce(0) { $0 + $1.sleepScore } / monthSessions.count
  }

  private var loudNights: Int {
    monthSessions.filter { session in
      guard let events = session.events else { return false }
      return events.contains { $0.intensity == .loud }
    }.count
  }
}
