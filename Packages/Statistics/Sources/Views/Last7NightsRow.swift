import DesignSystem
import FactoryKit
import Models
import SwiftUI

struct Last7NightsRow: View {
  let day: DaySummary
  let onTap: () -> Void
  @Injected(\.theme) private var theme

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
      Text(DurationFormatter.hoursAndMinutes(Int(day.totalDuration / 60)))
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundStyle(theme.textPrimary)

      Text("\(DurationFormatter.hoursAndMinutes(day.totalSnoringMinutes)) \(Strings.totalSnoringDurationColumn)")
        .font(.system(size: 12))
        .foregroundStyle(day.intensityColor)
    }
  }
}
