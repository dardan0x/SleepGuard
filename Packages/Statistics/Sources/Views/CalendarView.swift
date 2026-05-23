import SwiftUI
import SwiftData
import Models
import Env
import DesignSystem

@MainActor
public struct CalendarView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var selectedMonth: Date = Date()
  @State private var selectedDate: Date? = nil

  private let calendar = Calendar.current
  private var weekdaySymbols: [String] {
    let symbols = calendar.shortWeekdaySymbols
    let first = calendar.firstWeekday - 1
    return Array(symbols[first...] + symbols[..<first])
  }

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        CalendarMonthSelector(
          monthYearString: monthYearString,
          onPrevious: { selectedMonth = previousMonth },
          onNext: { selectedMonth = nextMonth }
        )

        CalendarDayHeaders(symbols: weekdaySymbols)

        CalendarGridView(
          days: calendarDays(),
          selectedDate: selectedDate,
          selectedMonth: selectedMonth,
          sessionForDate: sessionFor(date:),
          intensityColorForSession: intensityColor(for:),
          onSelectDate: { selectedDate = $0 }
        )

        CalendarMonthStatsView(monthSessions: sessionsInSelectedMonth)

        if let selected = selectedDate, let session = sessionFor(date: selected) {
          CalendarSelectedNightView(
            session: session,
            selectedDateString: selectedDateString
          )
        }

        SnoringLegendView()
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack(spacing: 6) {
          Image(systemName: "calendar")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
          Text(Strings.watchCalendar)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(theme.surface2)
        )
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = Date()
            selectedDate = calendar.startOfDay(for: Date())
          }
        } label: {
          Text(Strings.statsMiniChartToday)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }
    }
    .onAppear {
      selectedDate = calendar.startOfDay(for: Date())
    }
  }

  // MARK: - Helpers

  private var monthYearString: String {
    DateFormatters.monthYear.string(from: selectedMonth)
  }

  private var previousMonth: Date {
    calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
  }

  private var nextMonth: Date {
    calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
  }

  private var sessionsInSelectedMonth: [SleepSession] {
    sessions.filter { calendar.isDate($0.startDate, equalTo: selectedMonth, toGranularity: .month) }
  }

  private func sessionFor(date: Date) -> SleepSession? {
    sessions.first { calendar.isDate($0.startDate, inSameDayAs: date) }
  }

  private func intensityColor(for session: SleepSession?) -> Color {
    guard let session = session, let events = session.events, !events.isEmpty else {
      return Color.clear
    }
    let intensities = events.map(\.intensity)
    if intensities.contains(.epic) { return theme.snoreEpic }
    if intensities.contains(.loud) { return theme.snoreLoud }
    if intensities.contains(.light) { return theme.snoreLight }
    return theme.snoreQuiet
  }

  private func calendarDays() -> [CalendarDay] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
    let firstDayOfMonth = monthInterval.start

    let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
    let firstWeekday = calendar.firstWeekday
    let leadingDays = (weekdayOfFirst - firstWeekday + 7) % 7

    var days: [CalendarDay] = []

    // Leading days from previous month
    for offset in stride(from: leadingDays, to: 0, by: -1) {
      if let date = calendar.date(byAdding: .day, value: -offset, to: firstDayOfMonth) {
        days.append(CalendarDay(date: date))
      }
    }

    // Days in current month
    var current = firstDayOfMonth
    while calendar.isDate(current, equalTo: selectedMonth, toGranularity: .month) {
      days.append(CalendarDay(date: current))
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    // Trailing days to fill 6 rows (42 days total)
    while days.count < 42 {
      if let date = calendar.date(byAdding: .day, value: 1, to: days.last?.date ?? Date()) {
        days.append(CalendarDay(date: date))
      }
    }

    return days
  }

  private var selectedDateString: String {
    guard let date = selectedDate else { return "" }
    return DateFormatters.fullDayAndDate.string(from: date)
  }
}
