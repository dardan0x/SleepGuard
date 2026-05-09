import Foundation

public enum DateFormatters {
  public static let time: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }()

  public static let timeWithPeriod: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }()

  public static let dayOfWeekShort: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEE", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let dayOfWeekFull: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEE", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let monthDay: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM d", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let monthYear: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let dayOfWeekAndDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEE, MMM d", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let fullDayAndDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEE, MMM d", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let weekdayAndMonthDay: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEE MMM d", options: 0, locale: Locale.current)
    return formatter
  }()

  public static let mediumDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
  }()
}
