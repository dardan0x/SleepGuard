import SwiftUI
import Models
import DesignSystem

struct SessionDetailHeaderView: View {
  let session: SleepSession
  @Environment(Theme.self) private var theme

  var body: some View {
    HStack(spacing: 16) {
      SleepScoreGauge(score: session.sleepScore, theme: theme, size: 120)

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(
          icon: "clock",
          title: "Duration",
          value: durationString(session.totalDuration),
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
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return String(format: "%d:%02d", hours, minutes)
  }
}
