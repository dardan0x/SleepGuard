public import Foundation
import SleepAudioKit

/// A clip's waveform and spectrum for the player: SleepGuardShared's
/// `ClipWaveform` and `ClipSpectrum` (the same as SleepGuardUIKitWay's). Both
/// read the file off the caller's actor.
public enum WaveformGenerator {
  /// `pointCount` amplitude points, 0...1. With `maxDuration`, only the first
  /// `maxDuration` seconds: the waveform stays aligned with the event's
  /// measured length when the file has trailing silence.
  public static func generateSamples(from url: URL, pointCount: Int = 300, maxDuration: TimeInterval? = nil) async -> [Float] {
    await ClipWaveform().waveform(of: url, duration: maxDuration, pointCount: pointCount)
  }

  /// Averaged spectrum bars (0–1000 Hz), scaled so the highest is 1.
  public static func spectrumSamples(from url: URL, barCount: Int = 32) async -> [Float] {
    await ClipSpectrum.bars(of: url, barCount: barCount)
  }
}
