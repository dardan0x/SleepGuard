import Testing
@testable import AudioEngine

@MainActor
struct SnoreDetectorTests {
  @Test func noSignalClassifiesAsNone() {
    // No SoundAnalysis confidence and no spectral score: never fall back to dB alone.
    #expect(SnoreDetector.shared.classify(db: -5) == .none)
  }
}
