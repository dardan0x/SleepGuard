import AVFoundation
import Models
import Observation
import SleepCore

/// Detects sleep talking / speech in audio using SoundAnalysis confidence.
/// Designed to run in parallel with SnoreDetector. When both snoring and speech
/// are detected in the same sample, snoring takes priority (as documented in
/// the edge cases: "Snoring always takes priority in the classifier pipeline").
@MainActor
@Observable
public final class SpeechDetector {
  public static let shared = SpeechDetector()

  /// Whether speech is currently detected in the audio stream.
  public var isSpeechDetected = false

  /// Raw speech confidence from SoundAnalysis (0–1).
  public var speechConfidence: Float = 0

  /// Minimum confidence (0–1) required to classify audio as speech.
  public var confidenceThreshold: Float = 0.5

  /// Minimum dB floor. Sleep talking at nightstand distance is typically -50 to -60 dBFS,
  /// so -55 catches quiet mumbling/whispering without flooding the event list with ambient noise.
  public var dbFloor: Float = -55.0

  private init() {}

  /// Classifies whether the current audio contains speech.
  /// SleepCore's `SpeechClassifier` with this detector's threshold and floor.
  public func classify(db: Float, speechConfidence: Float) -> Bool {
    switch SpeechClassifier(confidenceThreshold: confidenceThreshold, dbFloor: dbFloor).verdict(db: db, speechConfidence: speechConfidence) {
    case .speech:
      return true
    case .lowConfidence:
      #if DEBUG
      Log.detection.debug("Rejected: confidence \(speechConfidence, format: .fixed(precision: 2)) < threshold \(self.confidenceThreshold)")
      #endif
      return false
    case .tooQuiet:
      #if DEBUG
      Log.detection.debug("Rejected: db \(db, format: .fixed(precision: 1)) < floor \(self.dbFloor)")
      #endif
      return false
    }
  }

  /// Updates the detector state with new audio features.
  public func update(db: Float, speechConfidence: Float) {
    self.speechConfidence = speechConfidence
    isSpeechDetected = classify(db: db, speechConfidence: speechConfidence)
  }
}
