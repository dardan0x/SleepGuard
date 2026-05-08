import SwiftUI
import Models
import DesignSystem

struct StatisticsStatsGrid: View {
  let session: SleepSession
  @Environment(Theme.self) private var theme

  var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    LazyVGrid(columns: columns, spacing: 12) {
      StatCard(
        icon: "clock",
        title: "Duration",
        value: durationString,
        theme: theme,
        iconColor: theme.accent
      )
      StatCard(
        icon: "percent",
        title: "Snoring",
        value: String(format: "%.0f%%", session.snoringPercentage),
        theme: theme,
        iconColor: theme.scoreAmber
      )
      StatCard(
        icon: "bolt.fill",
        title: "Events",
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: theme.scoreAmber
      )
    }
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    return String(format: "%d:%02d", hours, minutes)
  }
}
