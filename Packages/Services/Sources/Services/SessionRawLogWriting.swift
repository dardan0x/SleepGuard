import AudioEngine
public import Foundation
public import SleepCore

/// Writes the 20 Hz classification log. Fake: `FakeSessionRawLogWriter`.
public protocol SessionRawLogWriting: Actor {
  func start(sessionID: UUID, metadata: RawLogMetadata) async
  func append(
    at timestamp: Date,
    db: Float,
    peakDB: Float?,
    spectralScore: Float,
    snoreConfidence: Float,
    speechConfidence: Float,
    state: DetectionState) async
  func stop() async -> String?
  func discard() async
}
