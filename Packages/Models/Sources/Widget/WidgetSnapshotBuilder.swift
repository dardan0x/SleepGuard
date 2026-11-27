public import Foundation
public import SleepStore

public enum WidgetSnapshotBuilder {
  /// Builds a snapshot from completed sessions.
  ///
  /// Reads only the stored summary (`score`, `snoringDuration`) and never the
  /// `events` relationship, which has crashed when faulted. Nights without a
  /// summary or a length are skipped.
  public static func make(
    from sessions: [NightRecord],
    now: Date = .now,
    calendar: Calendar = .current) -> WidgetSnapshot
  {
    let nights = sessions
      .compactMap { session -> WidgetSnapshot.Night? in
        guard session.hasSummary, session.end > session.start else { return nil }
        return WidgetSnapshot.Night(
          id: session.id,
          startDate: session.start,
          endDate: session.end,
          score: session.score,
          snoringDuration: session.snoringDuration)
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
