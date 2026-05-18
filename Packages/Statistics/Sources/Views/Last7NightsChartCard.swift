import SwiftUI
import Models
import DesignSystem

struct Last7NightsChartCard: View {
  let days: [DaySummary]
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 12) {
      chartHeader

      barsSection

      SnoringLegendView()
    }
    .padding(theme.radiusCard)
    .overlay(
        RoundedRectangle(cornerRadius: theme.radiusCard)
          .stroke(theme.bgCard, lineWidth: 1)
      )
  }

  private var chartHeader: some View {
    HStack {
      Text(Strings.statsLast7nightsSnoringMin)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      Spacer()

      Text(Strings.statsLast7nightsTapAbar)
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(theme.textTertiary)
    }
  }

  private var barsSection: some View {
    VStack(spacing: 4) {
      HStack(alignment: .bottom, spacing: 4) {
        ForEach(days) { day in
          VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
              .fill(day.intensityColor)
              .frame(height: barHeight(for: day.totalSnoringMinutes))

            Text(day.label)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(theme.textTertiary)
              .frame(maxWidth: .infinity)
          }
        }
      }
      .frame(height: 80)
    }
  }

  private func barHeight(for minutes: Int) -> CGFloat {
    let maxMinutes = max(days.map(\.totalSnoringMinutes).max() ?? 1, 1)
    let ratio = CGFloat(minutes) / CGFloat(maxMinutes)
    return max(ratio * 80, 4)
  }
}
