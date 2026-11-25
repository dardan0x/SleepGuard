import Accelerate
public import AVFoundation
public import SleepCore

/// Spectral features of a buffer: SleepCore's type (the rules live there).
public typealias SpectralFeatures = SleepCore.SpectralFeatures

/// Performs real-time FFT analysis on audio buffers to detect snore-specific
/// spectral patterns: low-frequency dominance and harmonic structure.
public struct FFTAnalyzer {
  private let fftSetup: vDSP_DFT_Setup?
  private let bufferSize: Int

  public init(bufferSize: Int = 1024) {
    self.bufferSize = bufferSize
    // The DFT setup takes the transform length itself (not log2 of it).
    fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(bufferSize), .FORWARD)
  }

  /// Magnitude spectrum (first half) of the buffer's first `bufferSize` frames,
  /// zero-padded when the buffer is shorter, plus the Hz width of one bin.
  private func magnitudeSpectrum(of buffer: AVAudioPCMBuffer, sampleRate: Double) -> (magnitudes: [Float], freqResolution: Float)? {
    guard let channelData = buffer.floatChannelData?[0], bufferSize >= 64, let fftSetup else { return nil }

    let frameLength = min(Int(buffer.frameLength), bufferSize)
    var realInput = [Float](repeating: 0, count: bufferSize)
    for i in 0..<frameLength {
      realInput[i] = channelData[i]
    }
    var imagInput = [Float](repeating: 0, count: bufferSize)
    var realOutput = [Float](repeating: 0, count: bufferSize)
    var imagOutput = [Float](repeating: 0, count: bufferSize)
    vDSP_DFT_Execute(fftSetup, &realInput, &imagInput, &realOutput, &imagOutput)

    // FFT of a real signal is symmetric; keep the first half.
    let magnitudes = (0..<(bufferSize / 2)).map { hypot(realOutput[$0], imagOutput[$0]) }
    return (magnitudes, Float(sampleRate) / Float(bufferSize))
  }

  /// Spectral features of the buffer (SleepCore's rules on this transform).
  public func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) -> SpectralFeatures {
    guard let spectrum = magnitudeSpectrum(of: buffer, sampleRate: sampleRate) else { return .none }
    return SpectralFeatures(magnitudes: spectrum.magnitudes, binWidth: spectrum.freqResolution)
  }

  /// Magnitude spectrum grouped into `barCount` frequency bins (0–1000 Hz), 0–1.
  public func spectrumBars(buffer: AVAudioPCMBuffer, sampleRate: Double, barCount: Int = 32) -> [Float] {
    guard let spectrum = magnitudeSpectrum(of: buffer, sampleRate: sampleRate) else {
      return [Float](repeating: 0, count: barCount)
    }
    return SpectralFeatures.spectrumBars(magnitudes: spectrum.magnitudes, binWidth: spectrum.freqResolution, barCount: barCount)
  }
}
