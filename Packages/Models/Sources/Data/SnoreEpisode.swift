import Foundation

/// A group of adjacent snoring events that are close enough in time
/// to be considered a single snoring episode.
public struct SnoringEpisode: Identifiable, Sendable {
  public let id: UUID
  public let startTime: Date
  public let duration: TimeInterval
  public let intensity: SnoreIntensity
  public let events: [SnoreEvent]

  public var snoreDuration: TimeInterval {
    events.reduce(0) { $0 + $1.snoreDuration }
  }

  public var representativeEvent: SnoreEvent? {
    events.max(by: { $0.snoreDuration < $1.snoreDuration })
  }

  public var peakDB: Double {
    events.map(\.peakDB).max() ?? 0
  }

  public var averageDB: Double {
    let totalDB = events.reduce(0.0) { $0 + $1.averageDB * Double($1.snoreDuration) }
    let totalDuration = events.reduce(0.0) { $0 + $1.snoreDuration }
    return totalDuration > 0 ? totalDB / totalDuration : 0
  }
}
