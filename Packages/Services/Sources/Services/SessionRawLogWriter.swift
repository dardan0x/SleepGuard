import AudioEngine
public import Foundation
import Models
public import SleepCore
import SleepFiles

/// Writes the classification log while recording, as JSON Lines
/// (`rawlog_<id>.jsonl`, format 3; see `RawLog`). The log is the ground truth
/// for re-processing when thresholds or debounce values change.
///
/// The file itself is the shared `RawLogFile` (SleepGuardShared), written the
/// same way by SleepGuardUIKitWay: time order, an empty log removed. This
/// actor adds what only this app needs: samples one at a time, buffered and
/// appended every `flushThreshold` (about 10 s at 20 Hz), so memory stays flat
/// all night and a crash loses at most the last few seconds; and the logging.
public actor SessionRawLogWriter: SessionRawLogWriting {
  public static let shared = SessionRawLogWriter()
  static let flushThreshold = 200

  private let directory: URL
  private var buffer: [SnoreSample] = []
  private var sessionStart: Date?
  private var file: RawLogFile?

  public init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
    self.directory = directory
  }

  /// The log's file name for a session, known before the file exists, so the
  /// caller can register it for crash cleanup at start.
  public static func fileName(for sessionID: UUID) -> String {
    RawLogFile.fileName(for: sessionID)
  }

  public func start(sessionID: UUID, metadata: RawLogMetadata) async {
    await file?.discard()
    reset()
    do {
      file = try RawLogFile(night: sessionID, metadata: metadata, directory: directory)
      sessionStart = metadata.sessionStart
    } catch {
      Log.storage.error("Raw log couldn't be created: \(String(describing: error), privacy: .public)")
      try? FileManager.default.removeItem(at: directory.appendingPathComponent(Self.fileName(for: sessionID)))
      reset()
    }
  }

  /// `timestamp` is when the tracker processed the sample, not when this
  /// actor receives it: appends arrive through unstructured tasks, so they
  /// can be late and out of order. `RawLogFile` writes each batch in order.
  public func append(
    at timestamp: Date,
    db: Float,
    peakDB: Float?,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float,
    state: DetectionState) async
  {
    guard let sessionStart, file != nil else { return }
    buffer.append(SnoreSample(
      elapsed: timestamp.timeIntervalSince(sessionStart),
      db: db,
      peakDB: peakDB,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      speechConfidence: speechConfidence,
      state: state))
    if buffer.count >= Self.flushThreshold {
      await flush()
    }
  }

  /// Writes what's left and returns the filename. Returns `nil` (and deletes
  /// the file) when no sample was ever written.
  public func stop() async -> String? {
    await flush()
    let name = await file?.finish()
    reset()
    return name
  }

  public func discard() async {
    await file?.discard()
    reset()
  }

  private func flush() async {
    guard let file, !buffer.isEmpty else { return }
    let batch = buffer
    buffer.removeAll(keepingCapacity: true)
    do {
      try await file.append(batch)
    } catch {
      Log.storage.error("Raw log write failed, \(batch.count) samples lost: \(String(describing: error), privacy: .public)")
    }
  }

  private func reset() {
    buffer.removeAll(keepingCapacity: false)
    sessionStart = nil
    file = nil
  }
}
