import AVFoundation
import Testing
@testable import AudioEngine

/// Spectral features and spectrum bars from synthetic buffers
/// (44.1 kHz, 1024-point FFT → 43 Hz bins).
struct FFTAnalyzerTests {
  private let analyzer = FFTAnalyzer()

  // MARK: - analyze

  @Test func lowToneHasSnoreLikeFeatures() {
    let features = analyzer.analyze(buffer: TestAudio.sine(hz: 215), sampleRate: TestAudio.sampleRate)
    #expect(abs(features.dominantFrequency - 215) < 43)
    #expect(features.lowFreqRatio > 0.8)
    #expect(features.spectralCentroid < 400)
    #expect(features.spectralScore > 0.9)
  }

  @Test func highToneIsNotSnoreLike() {
    let features = analyzer.analyze(buffer: TestAudio.sine(hz: 2000), sampleRate: TestAudio.sampleRate)
    #expect(abs(features.dominantFrequency - 2000) < 43)
    #expect(features.lowFreqRatio < 0.1)
    #expect(features.spectralCentroid > 1500)
    #expect(features.spectralScore < 0.1)
  }

  @Test func whiteNoiseIsBelowTheSpectralGate() {
    let features = analyzer.analyze(buffer: TestAudio.noise(), sampleRate: TestAudio.sampleRate)
    #expect(features.lowFreqRatio < 0.1) // 100–500 Hz is ~2 % of 0–22 kHz
    #expect(features.spectralScore < 0.6)
  }

  @Test func silenceHasNoFrequencyContent() {
    let features = analyzer.analyze(buffer: TestAudio.silence(), sampleRate: TestAudio.sampleRate)
    #expect(features.lowFreqRatio == 0)
    #expect(features.dominantFrequency == 0)
    #expect(features.spectralCentroid == 0)
    // Only the centroid term contributes (centroid 0 → 0.3); still below the 0.6 gate.
    #expect(features.spectralScore < 0.6)
  }

  @Test func shortBufferIsZeroPadded() {
    let features = analyzer.analyze(buffer: TestAudio.sine(hz: 215, frames: 512), sampleRate: TestAudio.sampleRate)
    #expect(abs(features.dominantFrequency - 215) < 43)
    #expect(features.spectralScore > 0.9)
  }

  @Test func dominantFrequencyTracksTheSampleRate() {
    let features = analyzer.analyze(buffer: TestAudio.sine(hz: 300, sampleRate: 48000), sampleRate: 48000)
    #expect(abs(features.dominantFrequency - 300) < 47) // 48 kHz / 1024
  }

  // MARK: - spectrumBars

  @Test func spectrumBarsCoverAllBarsWithoutCrashing() {
    // 1024 frames at 44.1 kHz leaves only 22 bins below 1 kHz for 32 bars.
    let bars = analyzer.spectrumBars(buffer: TestAudio.sine(hz: 215), sampleRate: TestAudio.sampleRate)
    #expect(bars.count == 32)
    #expect(bars.max() == 1)
    #expect(bars.allSatisfy { (0...1).contains($0) })
  }

  @Test func spectrumBarsPeakAtTheTone() throws {
    // 500 Hz ≈ halfway through 0–1000 Hz → peak in the middle third of the bars.
    let bars = analyzer.spectrumBars(buffer: TestAudio.sine(hz: 500), sampleRate: TestAudio.sampleRate)
    let peak = try #require(bars.firstIndex(of: 1))
    #expect((11...21).contains(peak))
  }

  @Test func silenceGivesFlatZeroBars() {
    let bars = analyzer.spectrumBars(buffer: TestAudio.silence(), sampleRate: TestAudio.sampleRate, barCount: 16)
    #expect(bars == [Float](repeating: 0, count: 16))
  }
}
