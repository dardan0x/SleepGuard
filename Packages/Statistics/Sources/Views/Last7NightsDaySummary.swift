import SwiftUI
import Models
import DesignSystem

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

  var intensityColor: Color {
    let theme = Theme.shared
    switch maxIntensity {
    case .epic: return theme.snoreEpic
    case .loud: return theme.snoreLoud
    case .light: return theme.snoreLight
    case .quiet: return theme.snoreQuiet
    }
  }

  init(date: Date, sessions: [SleepSession]) {
    self.date = date
    self.avgScore = sessions.map(\.sleepScore).reduce(0, +) / max(sessions.count, 1)
    self.totalSnoringMinutes = Int(sessions.map(\.snoringDuration).reduce(0, +) / 60)
    self.totalEvents = sessions.map(\.eventsCount).reduce(0, +)
    self.totalDuration = sessions.map(\.totalDuration).reduce(0, +)
    self.maxIntensity = DaySummary.maxIntensity(for: sessions)
    self.label = String(DateFormatters.dayOfWeekShort.string(from: date).prefix(1).uppercased())
    self.weekday = DateFormatters.dayOfWeekShort.string(from: date)
    self.dateString = DateFormatters.monthDay.string(from: date)
    self.primarySessionId = sessions.first?.id
  }

  private static func maxIntensity(for sessions: [SleepSession]) -> SnoreIntensity {
    let allEvents = sessions.compactMap(\.events).flatMap { $0 }
    let intensities = allEvents.map(\.intensity)
    if intensities.contains(.epic) { return .epic }
    if intensities.contains(.loud) { return .loud }
    if intensities.contains(.light) { return .light }
    return .quiet
  }
}
