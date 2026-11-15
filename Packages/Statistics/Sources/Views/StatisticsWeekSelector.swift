import DesignSystem
import FactoryKit
import SleepCore
import SwiftUI

struct StatisticsWeekSelector: View {
  /// The 7 days ending today, from SleepCore's `NightDashboard.week(now:)`.
  let week: [NightDashboard.WeekDay]
  let onViewTrends: () -> Void
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text(Strings.statsTrendsThisWeekLabel)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        Spacer()

        Button {
          onViewTrends()
        } label: {
          Text(Strings.statsTrendsViewMonth)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      WeekStrip(days: week)
    }
  }
}
