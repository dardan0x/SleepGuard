import AVFoundation
import Observation

public enum SnoringState: String, Sendable, Codable {
  case none
  case quiet
  case light
  case loud
}

@MainActor
@Observable
public final class SnoreDetector {
  public static let shared = SnoreDetector()

  public var currentState: SnoringState = .none

  /// Thresholds in dB. Used together with spectral analysis.
  public var quietThreshold: Float = -35.0
  public var lightThreshold: Float = -25.0
  public var loudThreshold: Float = -15.0

  private init() {}

  // MARK: - Public Classification

  /// Classifies snoring using Apple's SoundAnalysis confidence when available,
  /// falling back to FFT spectral features if snoring is not a built-in class.
  public func classify(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) -> SnoringState {
    if snoreConfidence > 0 {
      return classifyWithSoundAnalysis(db: db, snoreConfidence: snoreConfidence)
    }
    if spectralScore > 0 {
      return classifyWithSpectral(db: db, spectralScore: spectralScore)
    }
    return classifyWithThresholds(db: db)
  }

  public func update(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) {
    currentState = classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
  }

  // MARK: - Threshold Fallback

  public func classifyWithThresholds(db: Float) -> SnoringState {
    if db >= loudThreshold {
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
  /// When SoundAnalysis is confident (≥0.5), we trust it over raw dB thresholds
  /// because the classifier distinguishes snoring from other loud sounds.
  /// dB is used only for intensity, with very low floors so quiet snoring
  /// (or low mic gain) is still captured.
  public func classifyWithSoundAnalysis(db: Float, snoreConfidence: Float) -> SnoringState {
    guard snoreConfidence >= 0.5 else {
      return .none
    }

    // Use much lower dB floors since SoundAnalysis already confirmed snoring.
    let floorLoud: Float = -25.0
    let floorLight: Float = -40.0
    let floorQuiet: Float = -60.0

    if db >= floorLoud && snoreConfidence >= 0.7 {
      return .loud
    } else if db >= floorLight && snoreConfidence >= 0.5 {
      return .light
    } else if db >= floorQuiet {
      return .quiet
    }
    // Even if dB is extremely low, if SoundAnalysis is ≥0.6 confident, count as quiet.
    return snoreConfidence >= 0.6 ? .quiet : .none
  }

  // MARK: - Spectral Classification

  /// Uses FFT spectral features to distinguish snoring from other loud sounds.
  /// Rejects sounds that are loud but don't have snore-like spectral structure.
  public func classifyWithSpectral(db: Float, spectralScore: Float) -> SnoringState {
    guard spectralScore >= 0.3 else {
      return .none
    }

    let adjustedQuiet = quietThreshold + (1.0 - spectralScore) * 10
    let adjustedLight = lightThreshold + (1.0 - spectralScore) * 8
    let adjustedLoud = loudThreshold + (1.0 - spectralScore) * 5

    if db >= adjustedLoud {
      return .loud
    } else if db >= adjustedLight {
      return .light
    } else if db >= adjustedQuiet {
      return .quiet
    }
    return .none
  }
}
