import Accelerate
import AVFoundation

/// Spectral features extracted from an audio buffer.
public struct SpectralFeatures {
  /// Ratio of energy in 100–500 Hz band to total spectral energy (0–1).
  public let lowFreqRatio: Float
  /// Weighted average frequency in Hz.
  public let spectralCentroid: Float
  /// Frequency of the highest-magnitude bin in Hz.
  public let dominantFrequency: Float
  /// Combined snore-likelihood score (0–1).
  public let spectralScore: Float
}

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

  /// Analyzes an audio buffer and returns spectral features.
  public func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) -> SpectralFeatures {
    guard let spectrum = magnitudeSpectrum(of: buffer, sampleRate: sampleRate) else {
      return SpectralFeatures(lowFreqRatio: 0, spectralCentroid: 0, dominantFrequency: 0, spectralScore: 0)
    }
    let (magnitudes, freqResolution) = spectrum
    let halfSize = magnitudes.count

    // Bin indices for frequency bands.
    let lowBin = max(1, Int(100.0 / Double(freqResolution))) // 100 Hz
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
    var maxMag: Float = 0
    var maxMagIndex = 0
    for i in 1..<halfSize {
      let freq = Float(i) * freqResolution
      let magSq = magnitudes[i] * magnitudes[i]
      weightedSum += freq * magSq
      if magnitudes[i] > maxMag {
        maxMag = magnitudes[i]
        maxMagIndex = i
      }
    }
    let spectralCentroid = totalEnergy > 1e-10 ? weightedSum / totalEnergy : 0
    let dominantFrequency = Float(maxMagIndex) * freqResolution

    // Combined snore-likelihood score.
    // Ideal snore: lowFreqRatio > 0.6, centroid < 400 Hz.
    let ratioScore = min(1.0, max(0, (lowFreqRatio - 0.3) / 0.4))
    let centroidScore = min(1.0, max(0, (800 - spectralCentroid) / 600))
    let spectralScore = ratioScore * 0.7 + centroidScore * 0.3

    return SpectralFeatures(
      lowFreqRatio: lowFreqRatio,
      spectralCentroid: spectralCentroid,
      dominantFrequency: dominantFrequency,
      spectralScore: spectralScore)
  }

  /// Returns magnitude spectrum grouped into `barCount` frequency bins (0–1000 Hz).
  public func spectrumBars(buffer: AVAudioPCMBuffer, sampleRate: Double, barCount: Int = 32) -> [Float] {
    guard let spectrum = magnitudeSpectrum(of: buffer, sampleRate: sampleRate) else {
      return [Float](repeating: 0, count: barCount)
    }
    let (magnitudes, freqResolution) = spectrum
    let halfSize = magnitudes.count
    let maxFreq: Float = 1000.0
    let maxBin = max(2, min(halfSize, Int(maxFreq / freqResolution)))
    // Spread bins 1..<maxBin evenly over the bars. With fewer bins than bars
    // (1024 frames at 44.1 kHz → 22 bins for 32 bars) neighbours share a bin,
    // and every range stays non-empty and in bounds.
    let usableBins = maxBin - 1

    var bars = [Float](repeating: 0, count: barCount)
    for bar in 0..<barCount {
      let startBin = 1 + bar * usableBins / barCount
      let endBin = max(startBin + 1, 1 + (bar + 1) * usableBins / barCount)
      var sum: Float = 0
      for i in startBin..<endBin {
        sum += magnitudes[i]
      }
      bars[bar] = sum / Float(max(1, endBin - startBin))
    }

    // Normalize to 0–1 range.
    if let maxVal = bars.max(), maxVal > 1e-10 {
      for i in 0..<barCount {
        bars[i] = bars[i] / maxVal
      }
    }

    return bars
  }
}
