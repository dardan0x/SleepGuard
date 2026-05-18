import SwiftUI
import Models
import DesignSystem

struct Last7NightsRow: View {
  let day: DaySummary
  let onTap: () -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    Button {
      onTap()
    } label: {
      HStack(spacing: 12) {
        scoreCircle

        dayDateColumn

        Spacer()

        durationSnoringColumn

        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(16)
      .overlay(
          RoundedRectangle(cornerRadius: theme.radiusCard)
            .stroke(theme.bgCard, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  private var scoreCircle: some View {
    ZStack {
      Circle()
        .stroke(theme.scoreColor(day.avgScore), lineWidth: 3)
        .frame(width: 44, height: 44)

      Text("\(day.avgScore)")
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(theme.textPrimary)
    }
  }

  private var dayDateColumn: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(day.weekday)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text(day.dateString)
        .font(.system(size: 12))
        .foregroundStyle(theme.textTertiary)
    }
  }

  private var durationSnoringColumn: some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(durationString(day.totalDuration))
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundStyle(theme.textPrimary)

      Text("\(day.totalSnoringMinutes)m snoring")
        .font(.system(size: 12))
        .foregroundStyle(day.intensityColor)
    }
  }

  private func durationString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }
}
