import Accelerate
import AVFoundation

/// Spectral features extracted from an audio buffer.
public struct SpectralFeatures {
  /// Ratio of energy in 100–500 Hz band to total spectral energy (0–1).
  public let lowFreqRatio: Float
  /// Weighted average frequency in Hz.
  public let spectralCentroid: Float
  /// Combined snore-likelihood score (0–1).
  public let spectralScore: Float
}

/// Performs real-time FFT analysis on audio buffers to detect snore-specific
/// spectral patterns: low-frequency dominance and harmonic structure.
public struct FFTAnalyzer {
  private let fftSetup: vDSP_DFT_Setup?
  private let log2n: vDSP_Length
  private let bufferSize: Int

  public init(bufferSize: Int = 1024) {
    self.bufferSize = bufferSize
    self.log2n = vDSP_Length(log2(Float(bufferSize)))
    self.fftSetup = vDSP_DFT_zop_CreateSetup(nil, log2n, .FORWARD)
  }

  /// Analyzes an audio buffer and returns spectral features.
  public func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) -> SpectralFeatures {
    guard let channelData = buffer.floatChannelData?[0],
          bufferSize >= 64 else {
      return SpectralFeatures(lowFreqRatio: 0, spectralCentroid: 0, spectralScore: 0)
    }

    let frameLength = min(Int(buffer.frameLength), bufferSize)
    let halfSize = frameLength / 2

    // Copy samples into mutable arrays for vDSP.
    var realInput = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    var imagInput = [Float](repeating: 0, count: frameLength)
    var realOutput = [Float](repeating: 0, count: frameLength)
    var imagOutput = [Float](repeating: 0, count: frameLength)

    // Perform complex FFT.
    guard let fftSetup else {
      return SpectralFeatures(lowFreqRatio: 0, spectralCentroid: 0, spectralScore: 0)
    }
    vDSP_DFT_Execute(fftSetup, &realInput, &imagInput, &realOutput, &imagOutput)

    // Compute magnitude spectrum (only first half; FFT of real signal is symmetric).
    var magnitudes = [Float](repeating: 0, count: halfSize)
    for i in 0..<halfSize {
      magnitudes[i] = hypot(realOutput[i], imagOutput[i])
    }

    let freqResolution = Float(sampleRate) / Float(frameLength)

    // Bin indices for frequency bands.
    let lowBin = max(1, Int(100.0 / Double(freqResolution)))    // 100 Hz
    let highBin = min(halfSize, Int(500.0 / Double(freqResolution))) // 500 Hz

    // Energy in snore-relevant band (100–500 Hz).
    var lowFreqEnergy: Float = 0
    for i in lowBin..<highBin {
      let mag = magnitudes[i]
      lowFreqEnergy += mag * mag
    }

    // Total energy.
    var totalEnergy: Float = 0
    for i in 1..<halfSize {
      let mag = magnitudes[i]
      totalEnergy += mag * mag
    }

    let lowFreqRatio = totalEnergy > 1e-10 ? lowFreqEnergy / totalEnergy : 0

    // Spectral centroid (weighted average frequency).
    var weightedSum: Float = 0
    for i in 1..<halfSize {
      let freq = Float(i) * freqResolution
      let magSq = magnitudes[i] * magnitudes[i]
      weightedSum += freq * magSq
    }
    let spectralCentroid = totalEnergy > 1e-10 ? weightedSum / totalEnergy : 0

    // Combined snore-likelihood score.
    // Ideal snore: lowFreqRatio > 0.6, centroid < 400 Hz.
    let ratioScore = min(1.0, max(0, (lowFreqRatio - 0.3) / 0.4))
    let centroidScore = min(1.0, max(0, (800 - spectralCentroid) / 600))
    let spectralScore = ratioScore * 0.7 + centroidScore * 0.3

    return SpectralFeatures(
      lowFreqRatio: lowFreqRatio,
      spectralCentroid: spectralCentroid,
      spectralScore: spectralScore
    )
  }
}
