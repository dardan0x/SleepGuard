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
  public var dominantFrequency: Double
  public var spectralCentroid: Double
  public var lowFreqRatio: Double
  public var audioFileURL: String?

  public var session: SleepSession?

  public init(
    id: UUID = UUID(),
    timestamp: Date,
    duration: TimeInterval,
    intensity: SnoreIntensity,
    averageDB: Double,
    peakDB: Double,
    dominantFrequency: Double = 0,
    spectralCentroid: Double = 0,
    lowFreqRatio: Double = 0,
    audioFileURL: String? = nil
  ) {
    self.id = id
    self.timestamp = timestamp
    self.duration = duration
    self.intensity = intensity
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.dominantFrequency = dominantFrequency
    self.spectralCentroid = spectralCentroid
    self.lowFreqRatio = lowFreqRatio
    self.audioFileURL = audioFileURL
  }
}
