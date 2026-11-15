import Foundation
import Models
import SleepCore

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
  let primarySessionId: UUID?

  /// Totals come from SleepCore's `NightDay`; this adds the labels.
  init(day: NightDay) {
    date = day.date
    avgScore = day.averageScore
    totalSnoringMinutes = day.snoringMinutes
    totalEvents = day.eventCount
    totalDuration = day.duration
    maxIntensity = day.loudestIntensity
    label = String(DateFormatters.dayOfWeekShort.string(from: day.date).prefix(1).uppercased())
    primarySessionId = day.nights.first?.id
  }
}
