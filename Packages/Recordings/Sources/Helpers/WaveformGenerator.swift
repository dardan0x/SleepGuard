import AVFoundation
import AudioEngine

/// Generates downsampled waveform amplitude samples and spectrum data from an audio file.
public enum WaveformGenerator {
  /// Reads an audio file and returns ~300 amplitude points for visualization.
  public static func generateSamples(from url: URL, pointCount: Int = 300) -> [Float] {
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      return []
    }

    let format = audioFile.processingFormat
    let sampleRate = format.sampleRate
    let totalFrames = Int(audioFile.length)
    guard totalFrames > 0, sampleRate > 0 else { return [] }

    let bufferSize = 1024
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferSize))!
    let framesPerPoint = max(1, totalFrames / pointCount)

    var samples = [Float](repeating: 0, count: pointCount)
    var pointIndex = 0
    var frameAccumulator: Float = 0
    var frameCount = 0

    while audioFile.framePosition < audioFile.length {
      do {
        try audioFile.read(into: buffer)
        guard let channelData = buffer.floatChannelData?[0] else { continue }
        let frameLength = Int(buffer.frameLength)

        for i in 0..<frameLength {
          let sample = abs(channelData[i])
          frameAccumulator += sample
          frameCount += 1

          if frameCount >= framesPerPoint {
            let average = frameAccumulator / Float(frameCount)
            if pointIndex < pointCount {
              samples[pointIndex] = average
              pointIndex += 1
            }
            frameAccumulator = 0
            frameCount = 0
          }
        }
      } catch {
        break
      }
    }

    // Normalize to 0–1
    if let maxVal = samples.max(), maxVal > 1e-10 {
      for i in 0..<samples.count {
        samples[i] = samples[i] / maxVal
      }
    }

    return samples
  }

  /// Reads an audio clip and returns averaged FFT magnitude bars for visualization.
  public static func spectrumSamples(from url: URL, barCount: Int = 32) -> [Float] {
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      return Array(repeating: 0, count: barCount)
    }

    let format = audioFile.processingFormat
    let sampleRate = format.sampleRate
    let bufferSize = 1024
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferSize))!
    let analyzer = FFTAnalyzer(bufferSize: bufferSize)

    var barAccumulators = [Float](repeating: 0, count: barCount)
    var barCounts = [Int](repeating: 0, count: barCount)

    while audioFile.framePosition < audioFile.length {
      do {
        try audioFile.read(into: buffer)
        let frameLength = Int(buffer.frameLength)
        if frameLength < bufferSize { continue }

        let bars = analyzer.spectrumBars(buffer: buffer, sampleRate: sampleRate, barCount: barCount)
        for i in 0..<barCount {
          barAccumulators[i] += bars[i]
          barCounts[i] += 1
        }
      } catch {
        break
      }
    }

    var bars = [Float](repeating: 0, count: barCount)
    for i in 0..<barCount {
      bars[i] = barCounts[i] > 0 ? barAccumulators[i] / Float(barCounts[i]) : 0
    }

    if let maxVal = bars.max(), maxVal > 1e-10 {
      for i in 0..<bars.count {
        bars[i] = bars[i] / maxVal
      }
    }

    return bars
  }
}
