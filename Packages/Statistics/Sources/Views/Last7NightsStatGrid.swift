import DesignSystem
import SwiftUI

struct Last7NightsStatGrid: View {
  let avgSnoringMinutes: Int
  let totalEvents: Int
  let bestScore: Int
  let bestDay: String
  let worstScore: Int
  let worstDay: String
  @Environment(Theme.self) private var theme

  var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    LazyVGrid(columns: columns, spacing: 8) {
      statCard(
        icon: "percent",
        iconColor: theme.scoreAmber,
        label: Strings.statsLast7nightsAvgSnoring,
        value: DurationFormatter.hoursAndMinutes(avgSnoringMinutes))

      statCard(
        icon: "bolt.fill",
        iconColor: theme.scoreAmber,
        label: Strings.statsLast7nightsTotalEvents,
        value: "\(totalEvents)")

      statCard(
        icon: "leaf.fill",
        iconColor: theme.scoreGreen,
        label: Strings.statsLast7nightsBest,
        value: "\(bestScore) \(bestDay)",
        valueColor: theme.scoreGreen)

      statCard(
        icon: "flame.fill",
        iconColor: theme.scoreRed,
        label: Strings.statsLast7nightsWorst,
        value: "\(worstScore) \(worstDay)",
        valueColor: theme.scoreRed)
    }
  }

  private func statCard(
    icon: String,
    iconColor: Color,
    label: String,
    value: String,
    valueColor: Color? = nil) -> some View
  {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(iconColor)

        Text(label)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(0.5)
      }

      Text(value)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(valueColor ?? theme.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusSmall)
  }
}
