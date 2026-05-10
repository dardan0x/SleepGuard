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
    totalDuration: TimeInterval = 0,
    snoringDuration: TimeInterval = 0,
    snoringPercentage: Double = 0,
    averageDB: Double = 0,
    peakDB: Double = 0,
    eventsCount: Int = 0,
    eventsPerHour: Double = 0,
    sleepScore: Int = 0,
    audioFileURL: String? = nil,
    rawAudioFileURL: String? = nil,
    rawLogFileURL: String? = nil
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
    self.audioFileURL = audioFileURL
    self.rawAudioFileURL = rawAudioFileURL
    self.rawLogFileURL = rawLogFileURL
  }
}
