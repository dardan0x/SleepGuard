import AudioEngine
import AVFoundation
import SleepCore

/// Generates downsampled waveform amplitude samples and spectrum data from an audio file.
public enum WaveformGenerator {
  /// Reads an audio file and returns ~300 amplitude points for visualization
  /// (SleepCore's `WaveformAccumulator`). When `maxDuration` is provided, only
  /// the first `maxDuration` seconds are sampled. This keeps the waveform
  /// aligned with the algorithm-defined event duration even when the
  /// underlying audio file contains trailing silence.
  public nonisolated static func generateSamples(from url: URL, pointCount: Int = 300, maxDuration: TimeInterval? = nil) -> [Float] {
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      return []
    }

    let format = audioFile.processingFormat
    let sampleRate = format.sampleRate
    let totalFrames = Int(audioFile.length)
    let maxFrames = maxDuration.map { min(totalFrames, Int($0 * sampleRate)) } ?? totalFrames
    guard maxFrames > 0, sampleRate > 0,
          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else { return [] }

    var waveform = WaveformAccumulator(frames: maxFrames, pointCount: pointCount)
    while audioFile.framePosition < audioFile.length, !waveform.isFull {
      do {
        try audioFile.read(into: buffer)
        guard let channelData = buffer.floatChannelData?[0] else { continue }
        waveform.add(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
      } catch {
        break
      }
    }
    return waveform.waveform
  }

  /// Reads an audio clip and returns averaged FFT magnitude bars for visualization.
  public nonisolated static func spectrumSamples(from url: URL, barCount: Int = 32) -> [Float] {
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
