import AVFoundation
import Observation

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

  /// Minimum dB floor. Very quiet speech (whispers below this level) is ignored
  /// to reduce false positives from ambient noise.
  public var dbFloor: Float = -40.0

  private init() {}

  /// Classifies whether the current audio contains speech.
  public func classify(db: Float, speechConfidence: Float) -> Bool {
    guard speechConfidence >= confidenceThreshold else { return false }
    guard db >= dbFloor else { return false }
    return true
  }

  /// Updates the detector state with new audio features.
  public func update(db: Float, speechConfidence: Float) {
    self.speechConfidence = speechConfidence
    isSpeechDetected = classify(db: db, speechConfidence: speechConfidence)
  }
}
