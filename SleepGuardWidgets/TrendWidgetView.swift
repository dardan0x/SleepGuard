import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct TrendWidgetView: View {
  let days: [WidgetSnapshot.Day]
  let theme = Theme.shared

  var body: some View {
    Group {
      if days.isEmpty {
        WidgetEmptyView()
      } else {
        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 2) {
            Text(Strings.widgetTrendLabel)
              .font(.caption2.weight(.semibold))
              .tracking(1)
              .foregroundStyle(theme.textTertiary)

            Text("\(averageScore)")
              .font(.system(size: 44, weight: .bold, design: .rounded))
              .foregroundStyle(theme.scoreColor(averageScore))

            Text(Strings.statsLast7nightsAvgSleepScore)
              .font(.caption)
              .foregroundStyle(theme.textSecondary)
          }

          MiniBarChart(data: chartData)
        }
      }
    }
    .containerBackground(theme.bgSecondary, for: .widget)
    .widgetURL((days.isEmpty ? WidgetDeepLink.startTracking : .last7Nights).url)
  }

  /// Same integer average as Last 7 Nights, so widget and app agree.
  private var averageScore: Int {
    days.map(\.averageScore).reduce(0, +) / max(days.count, 1)
  }

  /// Same bars as the dashboard's mini chart: weekday initial, score-colored.
  private var chartData: [MiniBarChart.DataPoint] {
    days.map { day in
      MiniBarChart.DataPoint(
        label: DateFormatters.dayOfWeekShort.string(from: day.date).prefix(1).uppercased(),
        value: Double(day.averageScore),
        color: theme.scoreColor(day.averageScore))
    }
  }
}
