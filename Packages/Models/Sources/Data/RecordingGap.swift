import Foundation

/// Represents an interval during a sleep session when the microphone was paused,
/// typically because Snore Interrupter playback took over the audio session.
/// Tracking these gaps allows stats to be calculated over "monitored duration"
/// rather than total session duration, and lets the UI be transparent about
/// detection blind spots.
public struct RecordingGap: Codable, Sendable {
  /// Seconds from the session start time when this gap begins.
  public let startOffset: TimeInterval
  /// Duration of the paused interval in seconds.
  public let duration: TimeInterval
  /// Whether snoring resumed after this gap within the breathing delay.
  /// Only gaps where snoring resumed count toward snoring duration.
  /// Defaults to `true` for legacy gaps created before this field existed.
  public var snoringResumed: Bool

  enum CodingKeys: String, CodingKey {
    case startOffset
    case duration
    case snoringResumed
  }

  public init(startOffset: TimeInterval, duration: TimeInterval, snoringResumed: Bool = true) {
    self.startOffset = startOffset
    self.duration = duration
    self.snoringResumed = snoringResumed
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.startOffset = try container.decode(TimeInterval.self, forKey: .startOffset)
    self.duration = try container.decode(TimeInterval.self, forKey: .duration)
    self.snoringResumed = (try? container.decode(Bool.self, forKey: .snoringResumed)) ?? true
  }
}
