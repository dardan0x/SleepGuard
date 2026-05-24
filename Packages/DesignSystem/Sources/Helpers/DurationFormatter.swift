import Foundation

public enum DurationFormatter {
  /// Formats minutes into "X h Y min" or "X min" when under 60.
  public static func hoursAndMinutes(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 {
      let hourLabel = hours == 1 ? Strings.timeHourSingular : Strings.timeHourPlural
      let minLabel = mins == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
      return "\(hours)\(hourLabel) \(mins) \(minLabel)"
    }
    let minLabel = mins == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
    return "\(mins) \(minLabel)"
  }
}
