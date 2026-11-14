import DesignSystem
import Env
import FactoryKit
import Models
import SleepCore
import SwiftData
import SwiftUI

@MainActor
public struct CalendarView: View {
  @Injected(\.theme) private var theme
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var selectedMonth = Date()
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
          onNext: { selectedMonth = nextMonth })

        CalendarDayHeaders(symbols: weekdaySymbols)

        CalendarGridView(
          days: calendarDays(),
          selectedDate: selectedDate,
          selectedMonth: selectedMonth,
          sessionForDate: sessionFor(date:),
          intensityColorForSession: intensityColor(for:),
          onSelectDate: { selectedDate = $0 })

        CalendarMonthStatsView(month: monthStats)

        if let selected = selectedDate, let session = sessionFor(date: selected) {
          CalendarSelectedNightView(
            session: session,
            selectedDateString: selectedDateString)
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

  /// The month's counts, from SleepCore's `CalendarMonth`. Chosen without
  /// reading events, then built in full for the month's nights only.
  private var monthStats: CalendarMonth {
    let chosen = CalendarMonth(month: selectedMonth, nights: sessions.summariesWithoutEvents, calendar: calendar).nights
    return CalendarMonth(month: selectedMonth, nights: sessions.fullSummaries(of: chosen), calendar: calendar)
  }

  /// The night shown for a grid day: SleepCore's `CalendarMonth` rule.
  private func sessionFor(date: Date) -> SleepSession? {
    guard let night = CalendarMonth.night(on: date, in: sessions.summariesWithoutEvents, calendar: calendar) else {
      return nil
    }
    return sessions.first { $0.id == night.id }
  }

  /// The loudest event's colour; none for a night without events.
  private func intensityColor(for session: SleepSession?) -> Color {
    guard let loudest = session?.nightSummary.loudestIntensity else { return Color.clear }
    return theme.intensityColor(loudest)
  }

  private func calendarDays() -> [CalendarDay] {
    CalendarMonth.grid(for: selectedMonth, calendar: calendar).map { CalendarDay(date: $0) }
  }

  private var selectedDateString: String {
    guard let date = selectedDate else { return "" }
    return DateFormatters.fullDayAndDate.string(from: date)
  }
}
