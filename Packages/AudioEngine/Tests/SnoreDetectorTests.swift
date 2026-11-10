import Testing
@testable import AudioEngine

/// Snore classification with the default (medium) thresholds:
/// quiet −50, light −40, loud −20, epic −10 dBFS; confidence gates 0.35 / 0.55 / 0.45.
/// Each test uses its own `SnoreDetector`, never `.shared`.
@MainActor
struct SnoreDetectorTests {
  // MARK: - Routing

  @Test func noSignalClassifiesAsNone() {
    // No SoundAnalysis confidence and no spectral score: never fall back to dB alone.
    #expect(SnoreDetector().classify(db: -5) == .none)
  }

  @Test func soundAnalysisWinsOverSpectral() {
    // Confidence below the gate rejects, even though the spectral path would say epic.
    #expect(SnoreDetector().classify(db: -5, spectralScore: 1, snoreConfidence: 0.2) == .none)
  }

  @Test func spectralIsUsedWithoutConfidence() {
    #expect(SnoreDetector().classify(db: -5, spectralScore: 1) == .epic)
  }

  @Test func updateStoresTheClassification() {
    let detector = SnoreDetector()
    detector.update(db: -30, snoreConfidence: 0.5)
    #expect(detector.currentState == .light)
    detector.update(db: -30)
    #expect(detector.currentState == DetectionState.none)
  }

  // MARK: - SoundAnalysis

  @Test(arguments: [
    (db: Float(-5), confidence: Float(0.34), expected: DetectionState.none), // below gate
    (-55, 0.35, .none), // at gate, below all dB floors, below fallback gate
    (-10, 0.55, .epic),
    (-10, 0.54, .loud), // epic needs the high-confidence gate
    (-20, 0.35, .loud),
    (-40, 0.35, .light),
    (-50, 0.35, .quiet),
    (-60, 0.45, .quiet), // below every floor but confident enough
    (-60, 0.44, .none),
  ])
  func soundAnalysisTiers(db: Float, confidence: Float, expected: DetectionState) {
    #expect(SnoreDetector().classifyWithSoundAnalysis(db: db, snoreConfidence: confidence) == expected)
  }

  // MARK: - Spectral

  @Test(arguments: [
    (db: Float(-5), score: Float(0.59), expected: DetectionState.none), // weak spectral match
    (-56, 1.0, .none), // below quiet − 5
    (-10, 1.0, .epic), // score 1 → base thresholds
    (-20, 1.0, .loud),
    (-40, 1.0, .light),
    (-50, 1.0, .quiet),
    (-51, 1.0, .none), // passes the −55 floor, under adjusted quiet
    // score 0.6 raises thresholds: quiet −46, light −36.8, loud −18, epic −8.8
    (-9, 0.6, .loud),
    (-17.9, 0.6, .loud),
    (-18.1, 0.6, .light),
    (-45.9, 0.6, .quiet),
    (-46.1, 0.6, .none),
  ])
  func spectralTiers(db: Float, score: Float, expected: DetectionState) {
    #expect(SnoreDetector().classifyWithSpectral(db: db, spectralScore: score) == expected)
  }

  // MARK: - Plain thresholds

  @Test(arguments: [
    (db: Float(-10), expected: DetectionState.epic),
    (-10.1, .loud),
    (-20, .loud),
    (-20.1, .light),
    (-40, .light),
    (-50, .quiet),
    (-50.1, .none),
  ])
  func thresholdBoundariesAreInclusive(db: Float, expected: DetectionState) {
    #expect(SnoreDetector().classifyWithThresholds(db: db) == expected)
  }

  // MARK: - Custom thresholds

  @Test func customThresholdsApplyToThatInstanceOnly() {
    let strict = SnoreDetector()
    strict.lightThreshold = -30
    strict.confidenceGate = 0.6
    #expect(strict.classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.7) == .quiet)
    #expect(strict.classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.5) == .none)
    #expect(SnoreDetector().classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.5) == .light)
  }
}
