import Foundation

public enum DateFormatters {
  public static let time: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm"
    return formatter
  }()

  public static let timeWithPeriod: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter
  }()

  public static let dayOfWeekShort: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
  }()

  public static let dayOfWeekFull: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
  }()

  public static let monthDay: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
  }()

  public static let monthYear: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  public static let dayOfWeekAndDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, MMM d"
    return formatter
  }()

  public static let fullDayAndDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d"
    return formatter
  }()

  public static let weekdayAndMonthDay: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE · MMM d"
    return formatter
  }()

  public static let mediumDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
  }()
}
