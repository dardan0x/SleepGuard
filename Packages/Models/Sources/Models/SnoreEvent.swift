import Foundation
import SwiftData

public enum SnoreIntensity: String, Codable, Sendable {
  case quiet
  case light
  case loud
}

@Model
public final class SnoreEvent {
  @Attribute(.unique) public var id: UUID
  public var timestamp: Date
  public var duration: TimeInterval
  public var intensity: SnoreIntensity
  public var averageDB: Double
  public var peakDB: Double
  public var audioFileURL: String?

  public var session: SleepSession?

  public init(
    id: UUID = UUID(),
    timestamp: Date,
    duration: TimeInterval,
    intensity: SnoreIntensity,
    averageDB: Double,
    peakDB: Double,
    audioFileURL: String? = nil
  ) {
    self.id = id
    self.timestamp = timestamp
    self.duration = duration
    self.intensity = intensity
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.audioFileURL = audioFileURL
  }
}
