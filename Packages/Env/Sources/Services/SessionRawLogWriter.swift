import AudioEngine
import Foundation

/// Buffers snore classification samples during a session and writes them to disk
/// as a JSON file on stop. The log becomes the ground truth for future re-processing
/// when thresholds or debounce values change.
public actor SessionRawLogWriter {
  public static let shared = SessionRawLogWriter()

  private var buffer: [SnoreSample] = []
  private var sessionStart: Date?
  private var logFileURL: URL?

  private init() {}

  public func start(sessionID: UUID) {
    buffer.removeAll(keepingCapacity: true)
    sessionStart = Date()
    logFileURL = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("rawlog_\(sessionID.uuidString).json")
  }

  public func append(db: Float, spectralScore: Float, snoreConfidence: Float, state: DetectionState) {
    guard let start = sessionStart else { return }
    let sample = SnoreSample(
      elapsed: Date().timeIntervalSince(start),
      db: db,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      state: state)
    buffer.append(sample)
  }

  /// Writes the buffered samples to disk and returns the filename.
  /// Returns `nil` if there are no samples or writing fails.
  public func stop() -> String? {
    guard let url = logFileURL, !buffer.isEmpty else {
      reset()
      return nil
    }

    do {
      let data = try JSONEncoder().encode(buffer)
      try data.write(to: url, options: .atomic)
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
    sessionStart = nil
    logFileURL = nil
  }
}
