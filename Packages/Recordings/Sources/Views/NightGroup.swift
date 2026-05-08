import Foundation
import Models

public struct NightGroup: Identifiable {
  public let id: String
  public let date: Date
  public let sessions: [SleepSession]

  public var recordingCount: Int { sessions.count }

  public var averageScore: Int {
    sessions.map(\.sleepScore).reduce(0, +) / sessions.count
  }

  public var totalDuration: TimeInterval {
    sessions.map(\.totalDuration).reduce(0, +)
  }

  public var totalEvents: Int {
    sessions.map(\.eventsCount).reduce(0, +)
  }

  public var latestSession: SleepSession { sessions.first! }
}
