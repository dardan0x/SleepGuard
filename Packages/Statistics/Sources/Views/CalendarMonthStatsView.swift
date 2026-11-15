import DesignSystem
import SleepCore
import SwiftUI

struct CalendarMonthStatsView: View {
  /// Counts and averages from SleepCore's `CalendarMonth`.
  let month: CalendarMonth

  var body: some View {
    HStack(spacing: 8) {
      CenteredStatTile(
        icon: "moon.fill",
        label: Strings.sessionsCalendarStatCardLabel,
        value: "\(month.nights.count)")
      CenteredStatTile(
        icon: "scope",
        label: Strings.avgScoreCalendarStatCardLabel,
        value: month.averageScore.map { "\($0)" } ?? "—")
      CenteredStatTile(
        icon: "speaker.wave.3.fill",
        label: Strings.loudNightsCalendarStatCardLabel,
        value: "\(month.loudNightCount)")
    }
  }
}
