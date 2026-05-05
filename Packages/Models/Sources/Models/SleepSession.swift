import Foundation
import SwiftData

@Model
public final class SleepSession {
  @Attribute(.unique) public var id: UUID
  public var startDate: Date
  public var endDate: Date?
  public var totalDuration: TimeInterval
  public var snoringDuration: TimeInterval
  public var snoringPercentage: Double
  public var averageDB: Double
  public var peakDB: Double
  public var eventsCount: Int
  public var eventsPerHour: Double
  public var sleepScore: Int

  @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session)
  public var events: [SnoreEvent]?

  public init(
    id: UUID = UUID(),
    startDate: Date,
    endDate: Date? = nil,
    totalDuration: TimeInterval = 0,
    snoringDuration: TimeInterval = 0,
    snoringPercentage: Double = 0,
    averageDB: Double = 0,
    peakDB: Double = 0,
    eventsCount: Int = 0,
    eventsPerHour: Double = 0,
    sleepScore: Int = 0
  ) {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.totalDuration = totalDuration
    self.snoringDuration = snoringDuration
    self.snoringPercentage = snoringPercentage
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.eventsCount = eventsCount
    self.eventsPerHour = eventsPerHour
    self.sleepScore = sleepScore
  }
}
