import DesignSystem
import FactoryKit
import SwiftUI

struct TrendsStatsGrid: View {
  let averageScore: Int
  let bestScore: Int
  let worstScore: Int
  let totalEvents: Int
  @Injected(\.theme) private var theme

  var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    LazyVGrid(columns: columns, spacing: 12) {
      StatTile(
        icon: "scope",
        iconColor: theme.accent,
        label: Strings.statsTrendsStatCardAvgScore,
        value: "\(averageScore)")
      StatTile(
        icon: "star.fill",
        iconColor: theme.scoreGreen,
        label: Strings.statsTrendsStatCardBestNight,
        value: "\(bestScore)")
      StatTile(
        icon: "bolt.fill",
        iconColor: theme.snoreLoud,
        label: Strings.statsTrendsStatCardWorstNight,
        value: "\(worstScore)")
      StatTile(
        icon: "number",
        iconColor: theme.textTertiary,
        label: Strings.statsTrendsStatCardTotalEvents,
        value: "\(totalEvents)")
    }
  }
}
