import SwiftUI
import DesignSystem

struct StatisticsWeekDay: Identifiable {
  let id = UUID()
  let label: String
  let number: String
  let isToday: Bool
  let dotColor: Color?
}

struct StatisticsWeekSelector: View {
  let weekDays: [StatisticsWeekDay]
  let onViewTrends: () -> Void
  @Environment(Theme.self) private var theme

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

      HStack(spacing: 0) {
        ForEach(weekDays, id: \.label) { day in
          VStack(spacing: 4) {
            Text(day.label)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(day.isToday ? theme.textPrimary : theme.textTertiary)
              .tracking(0.5)

            Text(day.number)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(day.isToday ? theme.textPrimary : theme.textSecondary)

            Circle()
              .fill(day.dotColor ?? Color.clear)
              .frame(width: 4, height: 4)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(day.isToday ? theme.bgCard : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .clipShape(RoundedRectangle(cornerRadius: theme.radiusCard))
    }
  }
}
