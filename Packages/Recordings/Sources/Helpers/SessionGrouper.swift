import Foundation
import Models

public enum SessionGrouper {
  public static func groupSessions(_ sessions: [SleepSession]) -> [MonthSection] {
    let calendar = Calendar.current

    // Group by month
    let monthGrouped = Dictionary(grouping: sessions) { session in
      calendar.dateComponents([.year, .month], from: session.startDate)
    }

    let sortedMonths = monthGrouped.sorted { a, b in
      if a.key.year != b.key.year {
        return a.key.year! > b.key.year!
      }
      return a.key.month! > b.key.month!
    }

    return sortedMonths.map { components, monthSessions in
      let monthDate = calendar.date(from: components)!
      let title = DateFormatters.monthYear.string(from: monthDate).uppercased()

      // Within each month, group by day
      let dayGrouped = Dictionary(grouping: monthSessions) { session in
        calendar.startOfDay(for: session.startDate)
      }

      let groups = dayGrouped.map { dayDate, daySessions in
        NightGroup(
          id: ISO8601DateFormatter.string(from: dayDate, timeZone: calendar.timeZone, formatOptions: [.withFullDate]),
          date: dayDate,
          sessions: daySessions.sorted { $0.startDate > $1.startDate }
        )
      }.sorted { $0.date > $1.date }

      return MonthSection(
        id: title,
        title: title,
        groups: groups
      )
    }
  }
}
