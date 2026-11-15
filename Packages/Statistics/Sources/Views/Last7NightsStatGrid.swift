import DesignSystem
import FactoryKit
import SwiftUI

struct Last7NightsStatGrid: View {
  let avgSnoringMinutes: Int
  let totalEvents: Int
  let bestScore: Int
  let bestDay: String
  let worstScore: Int
  let worstDay: String
  @Injected(\.theme) private var theme

  var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    LazyVGrid(columns: columns, spacing: 8) {
      StatTile(
        icon: "percent",
        iconColor: theme.scoreAmber,
        label: Strings.statsLast7nightsAvgSnoring,
        value: DurationFormatter.hoursAndMinutes(avgSnoringMinutes),
        valueSize: 22)

      StatTile(
        icon: "bolt.fill",
        iconColor: theme.scoreAmber,
        label: Strings.statsLast7nightsTotalEvents,
        value: "\(totalEvents)",
        valueSize: 22)

      StatTile(
        icon: "leaf.fill",
        iconColor: theme.scoreGreen,
        label: Strings.statsLast7nightsBest,
        value: "\(bestScore) \(bestDay)",
        valueSize: 22,
        valueColor: theme.scoreGreen)

      StatTile(
        icon: "flame.fill",
        iconColor: theme.scoreRed,
        label: Strings.statsLast7nightsWorst,
        value: "\(worstScore) \(worstDay)",
        valueSize: 22,
        valueColor: theme.scoreRed)
    }
  }
}
