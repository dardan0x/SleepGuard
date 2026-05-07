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
    VStack(spacing: 0) {
      navBar

      ScrollView {
        VStack(spacing: 16) {
          monthSelector

          dayHeaders

          calendarGrid

          monthStats

          if let selected = selectedDate, let session = sessionFor(date: selected) {
            selectedNightSection(session: session)
          }

          legend
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Calendar")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
    }
    .onAppear {
      selectedDate = calendar.startOfDay(for: Date())
    }
  }

  // MARK: - Nav Bar

  private var navBar: some View {
    HStack {
      Button {
        routerPath.navigateBack()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "chevron.left")
            .font(.system(size: 15, weight: .semibold))
          Text("Stats")
        }
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(theme.accent)
      }

      Spacer()

      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          selectedMonth = Date()
          selectedDate = calendar.startOfDay(for: Date())
        }
      } label: {
        Text("Today")
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(theme.accent)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
  }

  // MARK: - Month Selector

  private var monthSelector: some View {
    HStack {
      Text(monthYearString)
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      HStack(spacing: 16) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = previousMonth
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
        }

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = nextMonth
          }
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
        }
      }
    }
  }

  // MARK: - Day Headers

  private var dayHeaders: some View {
    HStack(spacing: 0) {
      ForEach(weekdaySymbols, id: \.self) { symbol in
        Text(symbol.prefix(1).uppercased())
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textTertiary)
          .frame(maxWidth: .infinity)
      }
    }
  }

  // MARK: - Calendar Grid

  private var calendarGrid: some View {
    let days = calendarDays()

    return VStack(spacing: 8) {
      ForEach(0..<6, id: \.self) { row in
        HStack(spacing: 0) {
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
    let session = sessionFor(date: day.date)
    let dotColor = intensityColor(for: session)

    return VStack(spacing: 2) {
      Text("\(calendar.component(.day, from: day.date))")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(
          isSelected ? .white :
            isToday ? theme.scoreGreen :
            isCurrentMonth ? theme.textPrimary : theme.textTertiary.opacity(0.5)
        )
        .frame(width: 36, height: 36)
        .background(
          isSelected ? theme.accent :
            isToday ? theme.scoreGreen.opacity(0.2) : Color.clear
        )
        .clipShape(Circle())

      Circle()
        .fill(dotColor)
        .frame(width: 4, height: 4)
        .opacity(dotColor == Color.clear ? 0 : 1)
    }
    .frame(maxWidth: .infinity, minHeight: 44)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.15)) {
        selectedDate = day.date
      }
    }
  }

  // MARK: - Month Stats

  private var monthStats: some View {
    let monthSessions = sessionsInSelectedMonth

    return HStack(spacing: 8) {
      CalendarStatCard(
        icon: "moon.fill",
        label: "SESSIONS",
        value: "\(monthSessions.count)",
        theme: theme
      )
      CalendarStatCard(
        icon: "scope",
        label: "AVG SCORE",
        value: monthSessions.isEmpty ? "—" : "\(avgScore(sessions: monthSessions))",
        theme: theme
      )
      CalendarStatCard(
        icon: "speaker.wave.3.fill",
        label: "LOUD NIGHTS",
        value: "\(loudNights(sessions: monthSessions))",
        theme: theme
      )
    }
  }

  // MARK: - Selected Night

  private func selectedNightSection(session: SleepSession) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("SELECTED NIGHT")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      HStack(spacing: 12) {
        SleepScoreGauge(score: session.sleepScore, theme: theme, size: 44)

        VStack(alignment: .leading, spacing: 2) {
          Text(selectedDateString)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(theme.textPrimary)

          Text(sessionDescription(session: session))
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)
      .contentShape(Rectangle())
      .onTapGesture {
        routerPath.navigate(to: .sessionDetail(id: session.id))
      }
    }
  }

  // MARK: - Legend

  private var legend: some View {
    HStack(spacing: 16) {
      legendItem(color: theme.snoreQuiet, label: "Quiet")
      legendItem(color: theme.snoreLight, label: "Light")
      legendItem(color: theme.snoreLoud, label: "Loud")
    }
    .frame(maxWidth: .infinity)
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)

      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(theme.textSecondary)
    }
  }

  // MARK: - Helpers

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: selectedMonth)
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

  private func avgScore(sessions: [SleepSession]) -> Int {
    guard !sessions.isEmpty else { return 0 }
    return sessions.reduce(0) { $0 + $1.sleepScore } / sessions.count
  }

  private func loudNights(sessions: [SleepSession]) -> Int {
    sessions.filter { session in
      guard let events = session.events else { return false }
      return events.contains { $0.intensity == .loud }
    }.count
  }

  private func sessionFor(date: Date) -> SleepSession? {
    sessions.first { calendar.isDate($0.startDate, inSameDayAs: date) }
  }

  private func intensityColor(for session: SleepSession?) -> Color {
    guard let session = session, let events = session.events, !events.isEmpty else {
      return Color.clear
    }
    let intensities = events.map(\.intensity)
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
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d"
    return formatter.string(from: date)
  }

  private func sessionDescription(session: SleepSession) -> String {
    let intensity: String
    if let events = session.events, !events.isEmpty {
      let loud = events.filter { $0.intensity == .loud }.count
      let light = events.filter { $0.intensity == .light }.count
      if loud > 0 { intensity = "Loud snoring" }
      else if light > 0 { intensity = "Light snoring" }
      else { intensity = "Quiet" }
    } else {
      intensity = "Quiet"
    }
    return "\(intensity) · score \(session.sleepScore)"
  }
}

// MARK: - Calendar Day

private struct CalendarDay: Identifiable {
  let id = UUID()
  let date: Date
}
