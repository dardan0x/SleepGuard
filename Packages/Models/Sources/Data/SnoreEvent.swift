import Foundation
import SwiftData

public enum SnoreIntensity: String, Codable, Sendable {
  case quiet
  case light
  case loud
  case epic

  public var rank: Int {
    switch self {
    case .quiet: return 0
    case .light: return 1
    case .loud: return 2
    case .epic: return 3
    }
  }
}

public enum SoundCategory: String, Codable, Sendable {
  case snoring
  case sleepTalking
  case coughing
  case noise
  case other
}

@Model
public final class SnoreEvent {
  @Attribute(.unique) public var id: UUID
  public var timestamp: Date
  public var category: SoundCategory = SoundCategory.snoring
  public var intensity: SnoreIntensity
  /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
  /// Values are relative and vary by microphone sensitivity and device distance.
  public var averageDB: Double
  /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
  public var peakDB: Double
  public var dominantFrequency: Double
  public var spectralCentroid: Double
  public var lowFreqRatio: Double
  public var averageConfidence: Double = 0
  public var averageSpectralScore: Double = 0
  public var audioFileURL: String?

  /// Total span of the snoring episode (from first to last detected snore).
  /// Includes natural breathing pauses within the episode, matching the
  /// clinical definition of a snoring epoch used by validated apps.
  public var duration: TimeInterval = 0

  /// Continuous snoring segments within this event. Used to create gap-free clips
  /// and analyze snoring fragmentation.
  public var bursts: [SnoreBurst]?

  public var session: SleepSession?

  public init(
    id: UUID = UUID(),
    timestamp: Date,
    category: SoundCategory = .snoring,
    intensity: SnoreIntensity,
    averageDB: Double,
    peakDB: Double,
    dominantFrequency: Double = 0,
    spectralCentroid: Double = 0,
    lowFreqRatio: Double = 0,
    averageConfidence: Double = 0,
    averageSpectralScore: Double = 0,
    audioFileURL: String? = nil,
    bursts: [SnoreBurst]? = nil,
    duration: TimeInterval = 0
  ) {
    self.id = id
    self.timestamp = timestamp
    self.category = category
    self.intensity = intensity
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.dominantFrequency = dominantFrequency
    self.spectralCentroid = spectralCentroid
    self.lowFreqRatio = lowFreqRatio
    self.averageConfidence = averageConfidence
    self.averageSpectralScore = averageSpectralScore
    self.audioFileURL = audioFileURL
    self.bursts = bursts
    self.duration = duration
  }

  /// Event-span duration including natural breathing pauses within the episode.
  /// Falls back to burst sum for legacy data created before the event-span
  /// duration field was added.
  public var snoreDuration: TimeInterval {
    duration > 0 ? duration : (bursts?.reduce(0) { $0 + $1.duration } ?? 0)
  }
}
