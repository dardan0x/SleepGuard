import Foundation
import Models

@MainActor
struct DaySummary: Identifiable {
  let id = UUID()
  let date: Date
  let avgScore: Int
  let totalSnoringMinutes: Int
  let totalEvents: Int
  let totalDuration: TimeInterval
  let maxIntensity: SnoreIntensity
  let label: String
  let weekday: String
  let dateString: String
  let primarySessionId: UUID?

  init(date: Date, sessions: [SleepSession]) {
    self.date = date
    avgScore = sessions.map(\.sleepScore).reduce(0, +) / max(sessions.count, 1)
    totalSnoringMinutes = Int(sessions.map(\.snoringDuration).reduce(0, +) / 60)
    totalEvents = sessions.map(\.eventsCount).reduce(0, +)
    totalDuration = sessions.map(\.totalDuration).reduce(0, +)
    maxIntensity = DaySummary.maxIntensity(for: sessions)
    label = String(DateFormatters.dayOfWeekShort.string(from: date).prefix(1).uppercased())
    weekday = DateFormatters.dayOfWeekShort.string(from: date)
    dateString = DateFormatters.monthDay.string(from: date)
    primarySessionId = sessions.first?.id
  }

  private static func maxIntensity(for sessions: [SleepSession]) -> SnoreIntensity {
    let allEvents = sessions.compactMap(\.events).flatMap(\.self)
    let intensities = allEvents.map(\.intensity)
    if intensities.contains(.epic) { return .epic }
    if intensities.contains(.loud) { return .loud }
    if intensities.contains(.light) { return .light }
    return .quiet
  }
}
