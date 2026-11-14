import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SleepCore
import SwiftUI

struct StatisticsMiniChartSection: View {
  let recentSessions: [SleepSession]
  @Injected(\.theme) private var theme
  @Environment(RouterPath.self) private var routerPath

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(Strings.statsTrendsLastSevenNights)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        Spacer()

        Button {
          routerPath.navigate(to: .last7Nights)
        } label: {
          Text(Strings.statsTrendsSeeAll)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      // One bar per day (several recordings on a night collapse), from
      // SleepCore's `NightDay`.
      let data = NightDay.days(from: recentSessions.summariesWithoutEvents).map { day in
        let label = DateFormatters.dayOfWeekShort.string(from: day.date).prefix(1).uppercased()
        return MiniBarChart.DataPoint(
          label: String(label),
          value: Double(day.averageScore),
          color: theme.scoreColor(day.averageScore),
          accessibilityLabel: DateFormatters.dayOfWeekFull.string(from: day.date),
          accessibilityValue: String(format: Strings.a11yScoreOutOf100, day.averageScore))
      }

      MiniBarChart(data: data)
    }
    .padding(12)
    .background(Color.clear)
    .cornerRadius(theme.radiusCard)
  }
}
