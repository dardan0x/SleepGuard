import Foundation
import SleepCore

/// A group of adjacent snoring events that are close enough in time
/// to be considered a single snoring episode.
public struct SnoringEpisode: Identifiable {
  public let id: UUID
  public let startTime: Date
  public let duration: TimeInterval
  public let intensity: SnoreIntensity
  public let events: [SnoreEvent]

  public var snoreDuration: TimeInterval {
    events.reduce(0) { $0 + $1.snoreDuration }
  }

  /// Actual detector-classified snoring duration, excluding melody gaps
  /// where the microphone was paused. Falls back to `snoreDuration` for
  /// legacy events that were saved before burst tracking was added.
  public var detectedDuration: TimeInterval {
    events.reduce(0) { $0 + ($1.bursts?.reduce(0) { $0 + $1.duration } ?? $1.snoreDuration) }
  }

  /// Renderable segments for the timeline. Uses bursts when available so
  /// melody gaps are not drawn as solid snoring blocks.
  public var detectedSegments: [(id: UUID, start: Date, duration: TimeInterval, intensity: SnoreIntensity)] {
    let hasBursts = events.contains { !($0.bursts?.isEmpty ?? true) }
    var segments: [(UUID, Date, TimeInterval, SnoreIntensity)] = []
    if hasBursts {
      for event in events {
        for burst in event.bursts ?? [] {
          segments.append((
            id: UUID(),
            start: event.timestamp.addingTimeInterval(burst.startOffset),
            duration: burst.duration,
            intensity: event.intensity))
        }
      }
    } else {
      for event in events {
        segments.append((
          id: UUID(),
          start: event.timestamp,
          duration: event.snoreDuration,
          intensity: event.intensity))
      }
    }
    return segments.sorted(by: { $0.1 < $1.1 })
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
