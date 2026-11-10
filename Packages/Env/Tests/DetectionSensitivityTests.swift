import Testing
@testable import AudioEngine
@testable import Env

/// Low / Medium / High presets that `RealtimeDetectionTracker` writes into the
/// snore detector. Each test uses its own detector, never `.shared`.
@MainActor
struct DetectionSensitivityTests {
  private func detector(after sensitivity: UserPreferences.DetectionSensitivity) -> SnoreDetector {
    let detector = SnoreDetector()
    RealtimeDetectionTracker(snoreDetector: detector).apply(sensitivity)
    return detector
  }

  private func values(_ d: SnoreDetector) -> [Float] {
    [d.quietThreshold, d.lightThreshold, d.loudThreshold, d.epicThreshold,
     d.confidenceGate, d.highConfidenceGate, d.quietFallbackGate]
  }

  @Test(arguments: [
    (UserPreferences.DetectionSensitivity.low, [Float(-45), -35, -15, -5, 0.45, 0.65, 0.55]),
    (.medium, [-50, -40, -20, -10, 0.35, 0.55, 0.45]),
    (.high, [-55, -45, -25, -15, 0.25, 0.45, 0.35]),
  ])
  func presetValues(sensitivity: UserPreferences.DetectionSensitivity, expected: [Float]) {
    #expect(values(detector(after: sensitivity)) == expected)
  }

  @Test func mediumMatchesTheDetectorDefaults() {
    #expect(values(detector(after: .medium)) == values(SnoreDetector()))
  }

  @Test func higherSensitivityLowersEveryThresholdAndGate() {
    let low = values(detector(after: .low))
    let medium = values(detector(after: .medium))
    let high = values(detector(after: .high))
    for i in low.indices {
      #expect(low[i] > medium[i])
      #expect(medium[i] > high[i])
    }
  }

  @Test func sameSoundIsClassifiedPerSensitivity() {
    // −42 dB at confidence 0.3: only High's 0.25 gate lets it through (light, floor −45).
    #expect(detector(after: .low).classify(db: -42, snoreConfidence: 0.3) == DetectionState.none)
    #expect(detector(after: .medium).classify(db: -42, snoreConfidence: 0.3) == DetectionState.none)
    #expect(detector(after: .high).classify(db: -42, snoreConfidence: 0.3) == .light)
  }

  @Test func applyingAPresetTwiceIsStable() {
    let detector = SnoreDetector()
    let tracker = RealtimeDetectionTracker(snoreDetector: detector)
    tracker.apply(.high)
    tracker.apply(.low)
    #expect(values(detector) == values(self.detector(after: .low)))
  }
}
