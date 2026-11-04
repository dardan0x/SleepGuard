import Foundation
import Models

public struct NightGroup: Identifiable {
  public let id: String
  public let date: Date
  public let sessions: [SleepSession]
  public let averageScore: Int
  public let totalDuration: TimeInterval
  public let totalEvents: Int

  public init(id: String, date: Date, sessions: [SleepSession]) {
    self.id = id
    self.date = date
    self.sessions = sessions
    averageScore = sessions.map(\.sleepScore).reduce(0, +) / max(sessions.count, 1)
    totalDuration = sessions.map(\.totalDuration).reduce(0, +)
    totalEvents = sessions.map(\.eventsCount).reduce(0, +)
  }

  public var recordingCount: Int { sessions.count }
  public var latestSession: SleepSession { sessions.first! }
}
