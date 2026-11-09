import Foundation

public enum WidgetSnapshotBuilder {
  /// Builds a snapshot from completed sessions.
  ///
  /// Reads only cached fields (`cachedSleepScore`, `cachedSnoringDuration`) and
  /// never the `events` relationship, which has crashed when faulted. Sessions
  /// without a cached score or an end date are skipped.
  public static func make(
    from sessions: [SleepSession],
    now: Date = .now,
    calendar: Calendar = .current) -> WidgetSnapshot
  {
    let nights = sessions
      .compactMap { session -> WidgetSnapshot.Night? in
        guard session.hasCachedScore, let endDate = session.endDate else { return nil }
        return WidgetSnapshot.Night(
          id: session.id,
          startDate: session.startDate,
          endDate: endDate,
          score: session.cachedSleepScore,
          snoringDuration: session.cachedSnoringDuration)
      }
      .sorted { $0.startDate < $1.startDate }

    let grouped = Dictionary(grouping: nights) { calendar.startOfDay(for: $0.startDate) }
    let recentDays = grouped
      .map { date, dayNights in
        WidgetSnapshot.Day(
          date: date,
          averageScore: dayNights.map(\.score).reduce(0, +) / dayNights.count)
      }
      .sorted { $0.date < $1.date }
      .suffix(7)

    return WidgetSnapshot(generatedAt: now, lastNight: nights.last, recentDays: Array(recentDays))
  }
}
