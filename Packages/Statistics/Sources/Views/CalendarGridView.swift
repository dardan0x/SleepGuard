import SwiftUI
import Models
import DesignSystem

struct CalendarDay: Identifiable {
  let id = UUID()
  let date: Date
}

struct CalendarGridView: View {
  let days: [CalendarDay]
  let selectedDate: Date?
  let selectedMonth: Date
  let sessionForDate: (Date) -> SleepSession?
  let intensityColorForSession: (SleepSession?) -> Color
  let onSelectDate: (Date) -> Void
  @Environment(Theme.self) private var theme

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 8) {
      ForEach(0..<6, id: \.self) { row in
        HStack(spacing: 8) {
          ForEach(0..<7, id: \.self) { col in
            let index = row * 7 + col
            if index < days.count {
              dayCell(day: days[index])
            }
          }
        }
      }
    }
  }

  private func dayCell(day: CalendarDay) -> some View {
    let isToday = calendar.isDate(day.date, inSameDayAs: Date())
    let isSelected = selectedDate.map { calendar.isDate(day.date, inSameDayAs: $0) } ?? false
    let isCurrentMonth = calendar.isDate(day.date, equalTo: selectedMonth, toGranularity: .month)
    let session = sessionForDate(day.date)
    let dotColor = intensityColorForSession(session)
    let hasEvents = dotColor != Color.clear
    let isHighlighted = isToday || isSelected

    let cellBackground: Color = {
      if isHighlighted { return theme.accent }
      if hasEvents { return theme.surface2 }
      return Color.clear
    }()

    let numberColor: Color = {
      if isHighlighted { return .white }
      if isCurrentMonth { return theme.textPrimary }
      return theme.textTertiary.opacity(0.5)
    }()

    return VStack(spacing: 4) {
      Text("\(calendar.component(.day, from: day.date))")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(numberColor)
        .frame(width: 36, height: 36)

      Circle()
        .fill(isHighlighted ? .white : dotColor)
        .frame(width: 5, height: 5)
        .opacity(hasEvents ? 1 : 0)
    }
    .frame(maxWidth: .infinity, minHeight: 52)
    .background(
      RoundedRectangle(cornerRadius: theme.radiusSmall)
        .fill(cellBackground)
    )
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.15)) {
        onSelectDate(day.date)
      }
    }
  }
}
