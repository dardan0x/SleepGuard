import Config
import SleepCore
import Testing
@testable import Services

/// Low / Medium / High: the tracker classifies with SleepCore's calibrated
/// preset for the chosen sensitivity (`LiveSampleClassifier`).
@MainActor
struct DetectionSensitivityTests {
  private func classifier(after sensitivity: UserPreferences.DetectionSensitivity) -> SnoreClassifier {
    let tracker = RealtimeDetectionTracker()
    tracker.apply(sensitivity)
    return tracker.classifier.snore
  }

  private func values(_ c: SnoreClassifier) -> [Float] {
    [c.quietThreshold, c.lightThreshold, c.loudThreshold, c.epicThreshold,
     c.confidenceGate, c.highConfidenceGate, c.quietFallbackGate]
  }

  @Test(arguments: [
    (UserPreferences.DetectionSensitivity.low, [Float(-45), -35, -15, -5, 0.45, 0.65, 0.55]),
    (.medium, [-50, -40, -20, -10, 0.35, 0.55, 0.45]),
    (.high, [-55, -45, -25, -15, 0.25, 0.45, 0.35]),
  ])
  func presetValues(sensitivity: UserPreferences.DetectionSensitivity, expected: [Float]) {
    #expect(values(classifier(after: sensitivity)) == expected)
  }

  @Test func sameSoundIsClassifiedPerSensitivity() {
    // −42 dB at confidence 0.3: only High's 0.25 gate lets it through (light, floor −45).
    #expect(classifier(after: .low).classify(db: -42, snoreConfidence: 0.3) == DetectionState.none)
    #expect(classifier(after: .medium).classify(db: -42, snoreConfidence: 0.3) == DetectionState.none)
    #expect(classifier(after: .high).classify(db: -42, snoreConfidence: 0.3) == .light)
  }

  @Test func applyingAPresetTwiceIsStable() {
    let tracker = RealtimeDetectionTracker()
    tracker.apply(.high)
    tracker.apply(.low)
    #expect(values(tracker.classifier.snore) == values(classifier(after: .low)))
  }
}
