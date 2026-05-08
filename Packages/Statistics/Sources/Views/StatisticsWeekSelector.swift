import SwiftUI
import DesignSystem

struct StatisticsWeekDay: Identifiable {
  let id = UUID()
  let label: String
  let number: String
  let isToday: Bool
}

struct StatisticsWeekSelector: View {
  let weekDays: [StatisticsWeekDay]
  let onViewTrends: () -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("THIS WEEK")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        Spacer()

        Button {
          onViewTrends()
        } label: {
          Text("View month >")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      HStack(spacing: 0) {
        ForEach(weekDays, id: \.label) { day in
          VStack(spacing: 4) {
            Text(day.label)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(day.isToday ? theme.accent : theme.textTertiary)

            Text(day.number)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(day.isToday ? .white : theme.textPrimary)
              .frame(width: 36, height: 36)
              .background(day.isToday ? theme.accent : Color.clear)
              .clipShape(Circle())
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
  }
}
