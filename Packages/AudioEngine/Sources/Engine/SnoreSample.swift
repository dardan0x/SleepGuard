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

/// A raw log: the detection settings in effect plus every sample, sorted by
/// `elapsed`.
///
/// Three on-disk formats; `decode(from:)` reads all of them:
/// - **3** (F23-T9, `rawlog_<id>.jsonl`): JSON Lines, written while recording.
///   Line 1 is the `RawLogMetadata`, every following line one `SnoreSample`,
///   in roughly arrival order. A log cut short by a crash still decodes: an
///   incomplete last line is dropped.
/// - **2** (F22-T1, `rawlog_<id>.json`): one `RawLog` JSON object.
/// - **1** (before F22-T1): a bare `[SnoreSample]` array with no metadata.
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
    if let samples = try? decoder.decode([SnoreSample].self, from: data) {
      return RawLog(metadata: nil, samples: samples)
    }
    return try decodeLines(data, decoder: decoder)
  }

  /// One format-3 line: `value` as JSON plus a newline.
  public static func line(_ value: some Encodable) throws -> Data {
    var data = try JSONEncoder().encode(value)
    data.append(0x0A)
    return data
  }

  private static func decodeLines(_ data: Data, decoder: JSONDecoder) throws -> RawLog {
    let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true)
    guard let header = lines.first else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty raw log")) }
    let metadata = try decoder.decode(RawLogMetadata.self, from: Data(header))
    var samples: [SnoreSample] = []
    samples.reserveCapacity(lines.count - 1)
    for (index, line) in lines.dropFirst().enumerated() {
      do {
        try samples.append(decoder.decode(SnoreSample.self, from: Data(line)))
      } catch where index == lines.count - 2 && data.last != 0x0A {
        // The app died mid-write: keep everything before the partial line.
        break
      }
    }
    return RawLog(metadata: metadata, samples: samples.sorted { $0.elapsed < $1.elapsed })
  }
}

/// Detection settings in effect when a raw log was recorded. A replay needs
/// them to configure the tracker the same way.
public struct RawLogMetadata: Codable, Sendable, Equatable {
  /// 3 = JSON Lines written while recording (F23-T9); 2 = `RawLog` object
  /// (samples carry `peakDB` / `speechConfidence`, timestamped at the
  /// tracker); 1 = bare sample array.
  public static let currentFormatVersion = 3

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
