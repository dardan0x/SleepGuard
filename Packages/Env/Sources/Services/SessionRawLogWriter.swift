import AudioEngine
import Foundation

/// Writes the 20 Hz classification log. Fake: `FakeSessionRawLogWriter`.
public protocol SessionRawLogWriting: Actor {
  func start(sessionID: UUID, metadata: RawLogMetadata)
  func append(
    at timestamp: Date,
    db: Float,
    peakDB: Float?,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float,
    state: DetectionState)
  func stop() -> String?
  func discard()
}

/// Buffers snore classification samples during a session and writes them to disk
/// as a JSON file on stop. The log becomes the ground truth for future re-processing
/// when thresholds or debounce values change.
public actor SessionRawLogWriter: SessionRawLogWriting {
  public static let shared = SessionRawLogWriter()

  private let directory: URL
  private var buffer: [SnoreSample] = []
  private var metadata: RawLogMetadata?
  private var logFileURL: URL?

  public init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
    self.directory = directory
  }

  public func start(sessionID: UUID, metadata: RawLogMetadata) {
    buffer.removeAll(keepingCapacity: true)
    self.metadata = metadata
    logFileURL = directory.appendingPathComponent("rawlog_\(sessionID.uuidString).json")
  }

  /// `timestamp` is when the tracker processed the sample, not when this
  /// actor receives it: appends arrive through unstructured tasks, so they
  /// can be late and out of order. `stop()` sorts by elapsed time.
  public func append(
    at timestamp: Date,
    db: Float,
    peakDB: Float?,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float,
    state: DetectionState)
  {
    guard let start = metadata?.sessionStart else { return }
    buffer.append(SnoreSample(
      elapsed: timestamp.timeIntervalSince(start),
      db: db,
      peakDB: peakDB,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      speechConfidence: speechConfidence,
      state: state))
  }

  /// Writes the buffered samples as a `RawLog` to disk and returns the filename.
  /// Returns `nil` if there are no samples or writing fails.
  public func stop() -> String? {
    guard let url = logFileURL, let metadata, !buffer.isEmpty else {
      reset()
      return nil
    }

    do {
      let log = RawLog(metadata: metadata, samples: buffer.sorted { $0.elapsed < $1.elapsed })
      try JSONEncoder().encode(log).write(to: url, options: .atomic)
      let filename = url.lastPathComponent
      reset()
      return filename
    } catch {
      reset()
      return nil
    }
  }

  public func discard() {
    if let url = logFileURL {
      try? FileManager.default.removeItem(at: url)
    }
    reset()
  }

  private func reset() {
    buffer.removeAll(keepingCapacity: false)
    metadata = nil
    logFileURL = nil
  }
}
