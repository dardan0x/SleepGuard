import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

/// Session summary top block: completion eyebrow, "You slept X" headline,
/// the sleep-score gauge, and the snoring/events stat cards.
struct SessionSummaryStats: View {
  @Injected(\.theme) private var theme
  @Injected(\.appConfig) private var appConfig

  let session: SleepSession

  var body: some View {
    VStack(spacing: 32) {
      VStack(spacing: 8) {
        Text(Strings.sessionSummaryTitle)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.scoreGreen)
          .tracking(2)

        Text(String(format: Strings.sessionSummaryYouSleptFormat, durationString))
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
      }
      .padding(.top, 16)

      SleepScoreGauge(score: session.sleepScore(using: appConfig.sleepScoreConfig), theme: theme, size: 160)

      HStack(spacing: 12) {
        StatCard(
          icon: "percent",
          title: Strings.sessionSummaryStatSnoring,
          value: String(format: "%.0f%%", session.snoringPercentage),
          theme: theme,
          iconColor: theme.scoreAmber)
        StatCard(
          icon: "bolt.fill",
          title: Strings.recordingsDetailEventsLabel,
          value: "\(session.eventsCount)",
          theme: theme,
          iconColor: theme.scoreAmber)
      }
    }
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }
}
