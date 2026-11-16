import AVFoundation
import Observation
import SleepCore

@MainActor
@Observable
public final class SnoreDetector {
  public static let shared = SnoreDetector()

  public var currentState: DetectionState = .none

  /// Base thresholds in dBFS (medium sensitivity defaults).
  /// These are relative to digital full scale, not calibrated dB-SPL.
  /// loud/epic lowered 5 dB (2026-06-01) because RMS over 23 ms buffers
  /// under-reports impulsive snoring peaks; peak-dB classification compensates.
  public var quietThreshold = SnoreClassifier.preset(.medium).quietThreshold
  public var lightThreshold = SnoreClassifier.preset(.medium).lightThreshold
  public var loudThreshold = SnoreClassifier.preset(.medium).loudThreshold
  public var epicThreshold = SnoreClassifier.preset(.medium).epicThreshold

  /// SoundAnalysis confidence gates (medium sensitivity defaults).
  /// `confidenceGate`: minimum to register as snoring at all.
  /// `highConfidenceGate`: required for epic.
  /// `quietFallbackGate`: counts as quiet even when dB is below all floors.
  public var confidenceGate = SnoreClassifier.preset(.medium).confidenceGate
  public var highConfidenceGate = SnoreClassifier.preset(.medium).highConfidenceGate
  public var quietFallbackGate = SnoreClassifier.preset(.medium).quietFallbackGate

  /// The current thresholds as SleepCore's classifier, which holds the rules.
  public var classifier: SnoreClassifier {
    SnoreClassifier(
      quietThreshold: quietThreshold, lightThreshold: lightThreshold, loudThreshold: loudThreshold,
      epicThreshold: epicThreshold, confidenceGate: confidenceGate, highConfidenceGate: highConfidenceGate,
      quietFallbackGate: quietFallbackGate)
  }

  /// Takes a preset's values (SleepCore's calibrated sensitivity presets).
  public func apply(_ preset: SnoreClassifier) {
    quietThreshold = preset.quietThreshold
    lightThreshold = preset.lightThreshold
    loudThreshold = preset.loudThreshold
    epicThreshold = preset.epicThreshold
    confidenceGate = preset.confidenceGate
    highConfidenceGate = preset.highConfidenceGate
    quietFallbackGate = preset.quietFallbackGate
  }

  /// Internal so tests can create isolated instances; app code uses `.shared`.
  init() {}

  // MARK: - Classification (SleepCore's `SnoreClassifier`)

  /// SoundAnalysis confidence when available, else FFT spectral features;
  /// never pure dB thresholds (no frequency discrimination).
  public func classify(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) -> DetectionState {
    classifier.classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
  }

  public func update(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) {
    currentState = classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
  }

  public func classifyWithThresholds(db: Float) -> DetectionState {
    classifier.classifyWithThresholds(db: db)
  }

  public func classifyWithSoundAnalysis(db: Float, snoreConfidence: Float) -> DetectionState {
    classifier.classifyWithSoundAnalysis(db: db, snoreConfidence: snoreConfidence)
  }

  public func classifyWithSpectral(db: Float, spectralScore: Float) -> DetectionState {
    classifier.classifyWithSpectral(db: db, spectralScore: spectralScore)
  }
}
