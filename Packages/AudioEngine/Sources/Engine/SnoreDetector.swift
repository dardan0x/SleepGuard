import AVFoundation
import Observation

public enum DetectionState: String, Sendable, Codable {
  case none
  case quiet
  case light
  case loud
  case epic
}

@MainActor
@Observable
public final class SnoreDetector {
  public static let shared = SnoreDetector()

  public var currentState: DetectionState = .none

  /// Base thresholds in dBFS (medium sensitivity defaults).
  /// These are relative to digital full scale, not calibrated dB-SPL.
  /// Recalibrated for the full-band capture path — the old -30/-20/-10/-5 was
  /// tuned for the narrow-bandpass build and sat above real snore levels.
  public var quietThreshold: Float = -50.0
  public var lightThreshold: Float = -40.0
  public var loudThreshold: Float = -25.0
  public var epicThreshold: Float = -15.0

  /// SoundAnalysis confidence gates (medium sensitivity defaults).
  /// `confidenceGate`: minimum to register as snoring at all.
  /// `highConfidenceGate`: required for loud/epic intensities.
  /// `quietFallbackGate`: counts as quiet even when dB is below all floors.
  /// Recalibrated from 0.5/0.7/0.6 — the old defaults were too strict and
  /// missed real bedroom snoring confirmed by independent burst analysis.
  public var confidenceGate: Float = 0.35
  public var highConfidenceGate: Float = 0.55
  public var quietFallbackGate: Float = 0.45

  private init() {}

  // MARK: - Public Classification

  /// Classifies snoring using Apple's SoundAnalysis confidence when available,
  /// falling back to FFT spectral features. Never falls back to pure dB thresholds
  /// because they have no frequency discrimination and create massive false positives
  /// (breathing, bed creaking, traffic, etc.).
  public func classify(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) -> DetectionState {
    if snoreConfidence > 0 {
      return classifyWithSoundAnalysis(db: db, snoreConfidence: snoreConfidence)
    }
    if spectralScore > 0 {
      return classifyWithSpectral(db: db, spectralScore: spectralScore)
    }
    return .none
  }

  public func update(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) {
    currentState = classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
  }

  // MARK: - Threshold Fallback

  public func classifyWithThresholds(db: Float) -> DetectionState {
    if db >= epicThreshold {
      return .epic
    } else if db >= loudThreshold {
      return .loud
    } else if db >= lightThreshold {
      return .light
    } else if db >= quietThreshold {
      return .quiet
    }
    return .none
  }

  // MARK: - SoundAnalysis Classification

  /// Uses Apple's built-in sound classifier confidence.
  /// `snoreConfidence` is 0–1 from the 300-class pre-trained model.
  ///
  /// Confidence gates are configurable per sensitivity. dB is used for intensity,
  /// with floors tuned to reduce false positives from ambient bedroom noise
  /// while still capturing quiet snoring.
  public func classifyWithSoundAnalysis(db: Float, snoreConfidence: Float) -> DetectionState {
    guard snoreConfidence >= confidenceGate else {
      return .none
    }

    // Floors are offset below base thresholds because ML already confirmed
    // snore-like spectral content. Keeps quiet snoring but rejects noise floor.
    let floorEpic: Float = epicThreshold
    let floorLoud: Float = loudThreshold - 5
    let floorLight: Float = lightThreshold - 10
    let floorQuiet: Float = quietThreshold - 15

    if db >= floorEpic && snoreConfidence >= highConfidenceGate {
      return .epic
    } else if db >= floorLoud && snoreConfidence >= highConfidenceGate {
      return .loud
    } else if db >= floorLight && snoreConfidence >= confidenceGate {
      return .light
    } else if db >= floorQuiet {
      return .quiet
    }
    // Even if dB is below all floors, sufficient classifier confidence counts as quiet.
    return snoreConfidence >= quietFallbackGate ? .quiet : .none
  }

  // MARK: - Spectral Classification

  /// Uses FFT spectral features to distinguish snoring from other loud sounds.
  /// Rejects sounds that are loud but don't have snore-like spectral structure.
  /// Threshold raised from 0.3 → 0.6 because breathing and other non-snore sounds
  /// easily score 0.4–0.7 in the 100–500 Hz band.
  public func classifyWithSpectral(db: Float, spectralScore: Float) -> DetectionState {
    guard spectralScore >= 0.6 else {
      return .none
    }

    // Require minimum dB even with good spectral score. Quiet ambient sounds
    // (breathing at -40 dB) should not trigger even if spectral looks similar.
    guard db >= quietThreshold - 5 else {
      return .none
    }

    let adjustedQuiet = quietThreshold + (1.0 - spectralScore) * 10
    let adjustedLight = lightThreshold + (1.0 - spectralScore) * 8
    let adjustedLoud = loudThreshold + (1.0 - spectralScore) * 5
    let adjustedEpic = epicThreshold + (1.0 - spectralScore) * 3

    if db >= adjustedEpic {
      return .epic
    } else if db >= adjustedLoud {
      return .loud
    } else if db >= adjustedLight {
      return .light
    } else if db >= adjustedQuiet {
      return .quiet
    }
    return .none
  }
}
