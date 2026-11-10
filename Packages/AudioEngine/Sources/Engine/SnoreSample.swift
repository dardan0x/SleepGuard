import Foundation

/// A single classification sample recorded during a sleep session.
/// Stored at ~20 Hz (every 50 ms) to create a ground-truth log that can be
/// re-processed later with different thresholds or debounce values.
///
/// Holds every input the detection tracker receives, so a log can be replayed
/// through it. `peakDB` and `speechConfidence` were added in F22-T1; logs
/// written before that decode them as `nil`.
public struct SnoreSample: Codable, Sendable, Equatable {
  /// Seconds elapsed since session start.
  public let elapsed: TimeInterval
  public let db: Float
  public let peakDB: Float?
  public let spectralScore: Float
  public let snoreConfidence: Float
  public let speechConfidence: Float?
  public let state: DetectionState

  public init(
    elapsed: TimeInterval,
    db: Float,
    peakDB: Float? = nil,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float? = nil,
    state: DetectionState)
  {
    self.elapsed = elapsed
    self.db = db
    self.peakDB = peakDB
    self.spectralScore = spectralScore
    self.snoreConfidence = snoreConfidence
    self.speechConfidence = speechConfidence
    self.state = state
  }
}

/// A `rawlog_<id>.json` file: the detection settings in effect plus every
/// sample, sorted by `elapsed`.
///
/// Format 1 (before F22-T1) is a bare `[SnoreSample]` array with no metadata;
/// `decode(from:)` reads both.
public struct RawLog: Codable, Sendable, Equatable {
  public let metadata: RawLogMetadata?
  public let samples: [SnoreSample]

  public init(metadata: RawLogMetadata?, samples: [SnoreSample]) {
    self.metadata = metadata
    self.samples = samples
  }

  public static func decode(from data: Data) throws -> RawLog {
    let decoder = JSONDecoder()
    if let log = try? decoder.decode(RawLog.self, from: data) {
      return log
    }
    return try RawLog(metadata: nil, samples: decoder.decode([SnoreSample].self, from: data))
  }
}

/// Detection settings in effect when a raw log was recorded. A replay needs
/// them to configure the tracker the same way.
public struct RawLogMetadata: Codable, Sendable, Equatable {
  /// 2 = `RawLog` object; samples carry `peakDB` / `speechConfidence` and are
  /// timestamped at the tracker. Format 1 is a bare sample array.
  public static let currentFormatVersion = 2

  public let formatVersion: Int
  public let sessionStart: Date
  public let detectionSensitivity: String
  public let detectSleepTalking: Bool
  public let snoreInterrupterMode: String

  public init(
    formatVersion: Int = RawLogMetadata.currentFormatVersion,
    sessionStart: Date,
    detectionSensitivity: String,
    detectSleepTalking: Bool,
    snoreInterrupterMode: String)
  {
    self.formatVersion = formatVersion
    self.sessionStart = sessionStart
    self.detectionSensitivity = detectionSensitivity
    self.detectSleepTalking = detectSleepTalking
    self.snoreInterrupterMode = snoreInterrupterMode
  }
}
