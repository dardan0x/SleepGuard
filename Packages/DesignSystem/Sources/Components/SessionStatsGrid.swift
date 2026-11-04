import Models
import SwiftUI

/// Reusable 2×2 stat grid for a sleep session.
@MainActor
public struct SessionStatsGrid: View {
  public let session: SleepSession
  @Environment(Theme.self) private var theme

  public init(session: SleepSession) {
    self.session = session
  }

  public var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    LazyVGrid(columns: columns, spacing: 12) {
      StatCard(
        icon: "clock",
        title: Strings.recordingsPlayerStatDuration,
        value: durationString(session.totalDuration),
        theme: theme,
        iconColor: theme.accent)
      StatCard(
        icon: "percent",
        title: Strings.sessionSummaryStatSnoring,
        value: String(format: "%.0f%%", session.snoringPercentage),
        theme: theme,
        iconColor: theme.scoreAmber)
      StatCard(
        icon: "waveform",
        title: Strings.sessionSummaryStatSnoreTime,
        value: durationString(session.snoringDuration),
        theme: theme,
        iconColor: theme.scoreRed)
      StatCard(
        icon: "bolt.fill",
        title: Strings.recordingsDetailEventsLabel,
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: theme.scoreAmber)
    }
  }

  private func durationString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }
}
