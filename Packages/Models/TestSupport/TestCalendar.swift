import Foundation

/// Fixed Gregorian/UTC calendar so date-based tests don't depend on the
/// simulator's time zone.
public enum TestCalendar {
  public static let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  public static func date(year: Int = 2026, month: Int = 11, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
  }
}
