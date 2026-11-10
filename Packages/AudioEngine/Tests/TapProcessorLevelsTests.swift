import AVFoundation
import Testing
@testable import AudioEngine

/// RMS and peak levels (dBFS) that `TapProcessor.process` reports for each
/// tapped buffer. No files or stream analyzer attached.
struct TapProcessorLevelsTests {
  private func levels(_ buffer: AVAudioPCMBuffer) -> TapProcessor.Levels {
    TapProcessor().process(buffer, sampleRate: TestAudio.sampleRate)
  }

  @Test func fullScaleSineIsZeroPeakAndMinusThreeRMS() {
    // RMS of a sine = amplitude / √2 → −3.01 dBFS at amplitude 1
    let result = levels(TestAudio.sine(hz: 1000, amplitude: 1))
    #expect(abs(result.peakDB) < 0.1)
    #expect(abs(result.db - -3.01) < 0.1)
  }

  @Test func tenthAmplitudeIsTwentyDecibelsLower() {
    let result = levels(TestAudio.sine(hz: 1000, amplitude: 0.1))
    #expect(abs(result.peakDB - -20) < 0.1)
    #expect(abs(result.db - -23.01) < 0.1)
  }

  @Test func singleSpikeRaisesPeakButBarelyRMS() {
    // One 0.5 sample in 1024: peak −6 dB; RMS 0.5/√1024 → −36 dB
    let result = levels(TestAudio.buffer { $0 == 100 ? 0.5 : 0 })
    #expect(abs(result.peakDB - -6.02) < 0.1)
    #expect(abs(result.db - -36.12) < 0.1)
  }

  @Test func silenceIsFloored() {
    let result = levels(TestAudio.silence())
    #expect(result.db == -200) // 20 × log10(1e-10)
    #expect(result.peakDB == -200)
  }

  @Test func processReportsTheSpectralScore() {
    #expect(levels(TestAudio.sine(hz: 215)).spectralScore > 0.9)
  }

  @Test func noFilesAttachedNeverDisablesWrites() {
    let processor = TapProcessor()
    for _ in 0..<5 {
      #expect(!processor.process(TestAudio.silence(), sampleRate: TestAudio.sampleRate).writesDisabled)
    }
    #expect(!processor.isWritingToFile)
  }
}
