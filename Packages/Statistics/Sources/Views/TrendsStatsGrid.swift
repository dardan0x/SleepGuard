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
      TrendStatCard(
        icon: "scope",
        iconColor: theme.accent,
        label: Strings.statsTrendsStatCardAvgScore,
        value: "\(averageScore)",
        theme: theme)
      TrendStatCard(
        icon: "star.fill",
        iconColor: theme.scoreGreen,
        label: Strings.statsTrendsStatCardBestNight,
        value: "\(bestScore)",
        theme: theme)
      TrendStatCard(
        icon: "bolt.fill",
        iconColor: theme.snoreLoud,
        label: Strings.statsTrendsStatCardWorstNight,
        value: "\(worstScore)",
        theme: theme)
      TrendStatCard(
        icon: "number",
        iconColor: theme.textTertiary,
        label: Strings.statsTrendsStatCardTotalEvents,
        value: "\(totalEvents)",
        theme: theme)
    }
  }
}
