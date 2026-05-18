import Foundation

/// Represents an interval during a sleep session when the microphone was paused,
/// typically because soothing melody playback took over the audio session.
/// Tracking these gaps allows stats to be calculated over "monitored duration"
/// rather than total session duration, and lets the UI be transparent about
/// detection blind spots.
public struct RecordingGap: Codable, Sendable {
  /// Seconds from the session start time when this gap begins.
  public let startOffset: TimeInterval
  /// Duration of the paused interval in seconds.
  public let duration: TimeInterval

  public init(startOffset: TimeInterval, duration: TimeInterval) {
    self.startOffset = startOffset
    self.duration = duration
  }
}
