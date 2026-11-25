public import Foundation
public import SleepCore

/// What clip extraction needs from an event, as a `Sendable` value. Callers map
/// their stored events to it, so the audio layer doesn't depend on the data model.
public struct ClipSource: Sendable {
  public let id: UUID
  public let timestamp: Date
  /// Measured snoring length (the event span, or the bursts' sum without one).
  public let snoreDuration: TimeInterval
  public let bursts: [SnoreBurst]?

  public init(id: UUID, timestamp: Date, snoreDuration: TimeInterval, bursts: [SnoreBurst]?) {
    self.id = id
    self.timestamp = timestamp
    self.snoreDuration = snoreDuration
    self.bursts = bursts
  }
}
