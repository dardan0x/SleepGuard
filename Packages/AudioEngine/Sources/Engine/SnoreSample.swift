import Foundation

/// A single classification sample recorded during a sleep session.
/// Stored at ~20 Hz (every 50 ms) to create a ground-truth log that can be
/// re-processed later with different thresholds or debounce values.
public struct SnoreSample: Codable, Sendable {
  /// Seconds elapsed since session start.
  public let elapsed: TimeInterval
  public let db: Float
  public let spectralScore: Float
  public let snoreConfidence: Float
  public let state: DetectionState

  public init(
    elapsed: TimeInterval,
    db: Float,
    spectralScore: Float,
    snoreConfidence: Float,
    state: DetectionState
  ) {
    self.elapsed = elapsed
    self.db = db
    self.spectralScore = spectralScore
    self.snoreConfidence = snoreConfidence
    self.state = state
  }
}
