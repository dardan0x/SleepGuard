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
