import Foundation

/// The data Home/Lock Screen widgets render, written by the app into the
/// shared App Group container. Widgets never open the SwiftData store.
public struct WidgetSnapshot: Codable, Sendable, Equatable {
  /// The most recent completed session.
  public struct Night: Codable, Sendable, Equatable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let score: Int
    public let snoringDuration: TimeInterval

    public var totalDuration: TimeInterval {
      endDate.timeIntervalSince(startDate)
    }

    public var snoringPercentage: Double {
      totalDuration > 0 ? (snoringDuration / totalDuration) * 100 : 0
    }

    public init(id: UUID, startDate: Date, endDate: Date, score: Int, snoringDuration: TimeInterval) {
      self.id = id
      self.startDate = startDate
      self.endDate = endDate
      self.score = score
      self.snoringDuration = snoringDuration
    }
  }

  /// Average score of all sessions started on one calendar day.
  public struct Day: Codable, Sendable, Equatable {
    public let date: Date
    public let averageScore: Int

    public init(date: Date, averageScore: Int) {
      self.date = date
      self.averageScore = averageScore
    }
  }

  public let generatedAt: Date
  public let lastNight: Night?
  /// Up to 7 most recent days with sessions, oldest first (matches Last 7 Nights).
  public let recentDays: [Day]

  public init(generatedAt: Date, lastNight: Night?, recentDays: [Day]) {
    self.generatedAt = generatedAt
    self.lastNight = lastNight
    self.recentDays = recentDays
  }
}
