import AVFoundation

/// Synthetic mono float buffers for audio tests.
enum TestAudio {
  static let sampleRate = 44100.0

  static func buffer(frames: Int = 1024, sampleRate: Double = sampleRate, _ sample: (Int) -> Float) -> AVAudioPCMBuffer {
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
    buffer.frameLength = AVAudioFrameCount(frames)
    for i in 0..<frames {
      buffer.floatChannelData![0][i] = sample(i)
    }
    return buffer
  }

  static func sine(hz: Double, amplitude: Float = 0.5, frames: Int = 1024, sampleRate: Double = sampleRate) -> AVAudioPCMBuffer {
    buffer(frames: frames, sampleRate: sampleRate) { amplitude * Float(sin(2 * .pi * hz * Double($0) / sampleRate)) }
  }

  static func silence(frames: Int = 1024) -> AVAudioPCMBuffer {
    buffer(frames: frames) { _ in 0 }
  }

  /// Deterministic white noise in −amplitude…amplitude (linear congruential generator).
  static func noise(amplitude: Float = 0.5, frames: Int = 1024) -> AVAudioPCMBuffer {
    var state: UInt32 = 12345
    return buffer(frames: frames) { _ in
      state = state &* 1_664_525 &+ 1_013_904_223
      return amplitude * (Float(state) / Float(UInt32.max) * 2 - 1)
    }
  }
}

extension TestAudio {
  /// Writes a mono float CAF of `seconds` length containing a sine at `hz`.
  static func writeTone(to url: URL, seconds: Double, hz: Double = 215, sampleRate: Double = sampleRate) throws {
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let file = try AVAudioFile(forWriting: url, settings: format.settings)
    let total = Int(seconds * sampleRate)
    let chunk = 4096
    var written = 0
    while written < total {
      let frames = min(chunk, total - written)
      let offset = written
      try file.write(from: buffer(frames: frames, sampleRate: sampleRate) {
        0.5 * Float(sin(2 * .pi * hz * Double(offset + $0) / sampleRate))
      })
      written += frames
    }
  }

  static func duration(of url: URL) async throws -> Double {
    try await AVURLAsset(url: url).load(.duration).seconds
  }
}

/// A fresh temporary folder per test suite instance, removed on deinit.
final class TempFolder {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio-tests-\(UUID().uuidString)")

  init() throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }

  deinit {
    try? FileManager.default.removeItem(at: url)
  }
}
