import DesignSystem
import Models
import SwiftUI

struct CalendarMonthStatsView: View {
  let monthSessions: [SleepSession]

  var body: some View {
    HStack(spacing: 8) {
      CalendarStatCard(
        icon: "moon.fill",
        label: Strings.sessionsCalendarStatCardLabel,
        value: "\(monthSessions.count)")
      CalendarStatCard(
        icon: "scope",
        label: Strings.avgScoreCalendarStatCardLabel,
        value: monthSessions.isEmpty ? "—" : "\(avgScore)")
      CalendarStatCard(
        icon: "speaker.wave.3.fill",
        label: Strings.loudNightsCalendarStatCardLabel,
        value: "\(loudNights)")
    }
  }

  private var avgScore: Int {
    guard !monthSessions.isEmpty else { return 0 }
    return monthSessions.reduce(0) { $0 + $1.sleepScore } / monthSessions.count
  }

  private var loudNights: Int {
    monthSessions.filter { session in
      guard let events = session.events else { return false }
      return events.contains { $0.intensity == .loud || $0.intensity == .epic }
    }.count
  }
}
