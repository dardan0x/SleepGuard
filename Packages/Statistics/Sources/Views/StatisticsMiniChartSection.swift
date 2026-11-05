import DesignSystem
import Env
import FactoryKit
import Models
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

      // Group sessions by day and average scores so multiple recordings
      // on the same night collapse to a single bar.
      let calendar = Calendar.current
      let grouped = Dictionary(grouping: recentSessions) {
        calendar.startOfDay(for: $0.startDate)
      }
      let dayAverages = grouped.map { date, sessions in
        let avg = sessions.map(\.sleepScore).reduce(0, +) / sessions.count
        return (date: date, score: avg)
      }.sorted { $0.date < $1.date }

      let data = dayAverages.map { day in
        let label = DateFormatters.dayOfWeekShort.string(from: day.date).prefix(1).uppercased()
        return MiniBarChart.DataPoint(
          label: String(label),
          value: Double(day.score),
          color: theme.scoreColor(day.score))
      }

      MiniBarChart(data: data, theme: theme)
    }
    .padding(12)
    .background(Color.clear)
    .cornerRadius(theme.radiusCard)
  }
}
