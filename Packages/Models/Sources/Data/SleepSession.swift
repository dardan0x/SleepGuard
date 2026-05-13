import Foundation
import SwiftData

@Model
public final class SleepSession {
  @Attribute(.unique) public var id: UUID
  public var startDate: Date
  public var endDate: Date?
  public var averageDB: Double
  public var peakDB: Double
  public var audioFileURL: String?

  /// Full session raw audio file preserved for future re-processing.
  /// When detection thresholds or debounce logic change, old sessions
  /// can be re-analysed from this file instead of using baked event data.
  public var rawAudioFileURL: String?

  /// Classification sample log (JSON) recorded at ~20 Hz during the session.
  /// Contains every sample's dB, spectral score, snore confidence, and state.
  /// Allows instant re-processing with different debounce or threshold values
  /// without re-running audio analysis.
  public var rawLogFileURL: String?

  @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session)
  public var events: [SnoreEvent]?

  public static let minimumSaveDuration: TimeInterval = 600

  public init(
    id: UUID = UUID(),
    startDate: Date,
    endDate: Date? = nil,
    averageDB: Double = 0,
    peakDB: Double = 0,
    audioFileURL: String? = nil,
    rawAudioFileURL: String? = nil,
    rawLogFileURL: String? = nil
  ) {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.audioFileURL = audioFileURL
    self.rawAudioFileURL = rawAudioFileURL
    self.rawLogFileURL = rawLogFileURL
  }

  /// Derived from raw data. Computed on demand so formula changes retroactively affect all sessions.
  public var totalDuration: TimeInterval {
    endDate?.timeIntervalSince(startDate) ?? 0
  }

  public var snoringDuration: TimeInterval {
    events?.reduce(0) { $0 + $1.snoreDuration } ?? 0
  }

  public var snoringPercentage: Double {
    totalDuration > 0 ? (snoringDuration / totalDuration) * 100 : 0
  }

  public var eventsCount: Int {
    events?.count ?? 0
  }

  public var eventsPerHour: Double {
    totalDuration > 0 ? Double(eventsCount) / (totalDuration / 3600) : 0
  }

  public var sleepScore: Int {
    let events = self.events ?? []
    let totalDuration = self.totalDuration
    let eventCount = events.count

    guard totalDuration > 0, eventCount > 0 else {
      return 100
    }

    var snoringDuration: TimeInterval = 0
    var lightDuration: TimeInterval = 0
    var loudDuration: TimeInterval = 0

    for event in events {
      let duration = event.snoreDuration
      snoringDuration += duration
      switch event.intensity {
      case .light:
        lightDuration += duration
      case .loud:
        loudDuration += duration
      case .quiet:
        break
      }
    }

    let snoringPercentage = (snoringDuration / totalDuration) * 100
    let snoringPenalty = min(Int(snoringPercentage * 0.7), 70)
    let eventsPenalty = min(Int(Double(eventCount) / (totalDuration / 3600) * 2), 20)

    let lightRatio = snoringDuration > 0 ? lightDuration / snoringDuration : 0
    let loudRatio = snoringDuration > 0 ? loudDuration / snoringDuration : 0
    let intensityPenalty = min(Int(lightRatio * 10 + loudRatio * 20), 20)

    return max(0, 100 - snoringPenalty - eventsPenalty - intensityPenalty)
  }
}
