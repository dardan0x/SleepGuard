import AudioEngine
import Foundation
import Models

/// Writes the classification log while recording, as JSON Lines
/// (`rawlog_<id>.jsonl`, format 3; see `RawLog`). The log is the ground truth
/// for re-processing when thresholds or debounce values change.
///
/// Samples are buffered briefly and appended every `flushThreshold` samples
/// (about 10 s at 20 Hz), so memory stays flat all night and a crash loses at
/// most the last few seconds. Before F23-T9 the whole night (~600k samples) sat
/// in memory and was encoded at stop, so a crash lost all of it.
public actor SessionRawLogWriter: SessionRawLogWriting {
  public static let shared = SessionRawLogWriter()
  static let flushThreshold = 200

  private let directory: URL
  private var buffer: [SnoreSample] = []
  private var metadata: RawLogMetadata?
  private var logFileURL: URL?
  private var handle: FileHandle?
  private var samplesWritten = 0

  public init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
    self.directory = directory
  }

  /// The log's file name for a session, known before the file exists, so the
  /// caller can register it for crash cleanup at start.
  public static func fileName(for sessionID: UUID) -> String {
    "rawlog_\(sessionID.uuidString).jsonl"
  }

  public func start(sessionID: UUID, metadata: RawLogMetadata) {
    close()
    reset()
    let url = directory.appendingPathComponent(Self.fileName(for: sessionID))
    do {
      try RawLog.line(metadata).write(to: url, options: .atomic)
      handle = try FileHandle(forWritingTo: url)
      try handle?.seekToEnd()
      self.metadata = metadata
      logFileURL = url
    } catch {
      Log.storage.error("Raw log couldn't be created: \(String(describing: error), privacy: .public)")
      try? FileManager.default.removeItem(at: url)
      reset()
    }
  }

  /// `timestamp` is when the tracker processed the sample, not when this
  /// actor receives it: appends arrive through unstructured tasks, so they
  /// can be late and out of order. Readers sort by elapsed time.
  public func append(
    at timestamp: Date,
    db: Float,
    peakDB: Float?,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float,
    state: DetectionState)
  {
    guard let start = metadata?.sessionStart, handle != nil else { return }
    buffer.append(SnoreSample(
      elapsed: timestamp.timeIntervalSince(start),
      db: db,
      peakDB: peakDB,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      speechConfidence: speechConfidence,
      state: state))
    if buffer.count >= Self.flushThreshold {
      flush()
    }
  }

  /// Writes what's left and returns the filename. Returns `nil` (and deletes
  /// the file) when no sample was ever written.
  public func stop() -> String? {
    flush()
    close()
    defer { reset() }
    guard let url = logFileURL else { return nil }
    guard samplesWritten > 0 else {
      try? FileManager.default.removeItem(at: url)
      return nil
    }
    return url.lastPathComponent
  }

  public func discard() {
    close()
    if let url = logFileURL {
      try? FileManager.default.removeItem(at: url)
    }
    reset()
  }

  private func flush() {
    guard let handle, !buffer.isEmpty else { return }
    do {
      var chunk = Data()
      for sample in buffer.sorted(by: { $0.elapsed < $1.elapsed }) {
        try chunk.append(RawLog.line(sample))
      }
      try handle.write(contentsOf: chunk)
      samplesWritten += buffer.count
    } catch {
      Log.storage.error("Raw log write failed, \(self.buffer.count) samples lost: \(String(describing: error), privacy: .public)")
    }
    buffer.removeAll(keepingCapacity: true)
  }

  private func close() {
    try? handle?.close()
    handle = nil
  }

  private func reset() {
    buffer.removeAll(keepingCapacity: false)
    metadata = nil
    logFileURL = nil
    samplesWritten = 0
  }
}
