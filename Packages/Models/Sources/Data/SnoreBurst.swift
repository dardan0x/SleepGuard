import Foundation

/// A continuous segment of snoring within a `SnoreEvent`.
/// Events can contain multiple bursts separated by brief gaps (< 3 s);
/// tracking bursts allows extracting gap-free clips and computing
/// true snoring duration (sum of burst lengths, not event span).
public struct SnoreBurst: Codable, Sendable, Equatable {
  /// Seconds from the event start time when this burst begins.
  public let startOffset: TimeInterval
  /// Seconds from the event start time when this burst ends.
  public let endOffset: TimeInterval

  public var duration: TimeInterval {
    endOffset - startOffset
  }

  public init(startOffset: TimeInterval, endOffset: TimeInterval) {
    self.startOffset = startOffset
    self.endOffset = endOffset
  }
}
