import AVFoundation
import os
import SoundAnalysis

/// Audio-thread half of `AudioRecorder`.
///
/// AVAudioEngine calls the input tap on a thread other than the main thread
/// (Apple documents only that, not which thread). Under Swift 6 a tap
/// closure written inside the `@MainActor` recorder inherits main-actor
/// isolation and traps there (`_dispatch_assert_queue_fail`). So the tap
/// closure is `@Sendable` (nonisolated) and everything it touches lives here,
/// behind a lock, instead of on the recorder.
final class TapProcessor: Sendable {
  struct Levels: Sendable {
    let db: Float
    let peakDB: Float
    let spectralScore: Float
    /// True when file writes were just disabled after repeated failures.
    let writesDisabled: Bool
  }

  private struct State {
    var fftAnalyzer = FFTAnalyzer(bufferSize: 1024)
    var streamAnalyzer: SNAudioStreamAnalyzer?
    var framePosition: AVAudioFramePosition = 0
    var audioFile: AVAudioFile?
    var eventFile: AVAudioFile?
    var consecutiveWriteFailures = 0
  }

  private let state = OSAllocatedUnfairLock(uncheckedState: State())

  var audioFile: AVAudioFile? {
    get { state.withLockUnchecked { $0.audioFile } }
    set { state.withLockUnchecked { $0.audioFile = newValue } }
  }

  var eventFile: AVAudioFile? {
    get { state.withLockUnchecked { $0.eventFile } }
    set { state.withLockUnchecked { $0.eventFile = newValue } }
  }

  var streamAnalyzer: SNAudioStreamAnalyzer? {
    get { state.withLockUnchecked { $0.streamAnalyzer } }
    set { state.withLockUnchecked { $0.streamAnalyzer = newValue } }
  }

  var isWritingToFile: Bool {
    state.withLockUnchecked { $0.audioFile != nil || $0.eventFile != nil }
  }

  /// Clears everything except the FFT setup. Called when recording stops.
  func reset() {
    state.withLockUnchecked {
      $0.streamAnalyzer = nil
      $0.framePosition = 0
      $0.audioFile = nil
      $0.eventFile = nil
      $0.consecutiveWriteFailures = 0
    }
  }

  /// Runs on the tap's (non-main) thread for every tapped buffer.
  func process(_ buffer: AVAudioPCMBuffer, sampleRate: Double) -> Levels {
    let db = Self.rmsDB(buffer)
    let peakDB = Self.peakDB(buffer)
    return state.withLockUnchecked { s in
      let features = s.fftAnalyzer.analyze(buffer: buffer, sampleRate: sampleRate)
      s.streamAnalyzer?.analyze(buffer, atAudioFramePosition: s.framePosition)
      s.framePosition += AVAudioFramePosition(buffer.frameLength)

      var didWrite = false
      if let audioFile = s.audioFile {
        do {
          try audioFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write audio buffer: \(error)")
        }
      }
      if let eventFile = s.eventFile {
        do {
          try eventFile.write(from: buffer)
          didWrite = true
        } catch {
          print("[AudioRecorder] Failed to write event buffer: \(error)")
        }
      }
      var writesDisabled = false
      if didWrite {
        s.consecutiveWriteFailures = 0
      } else if s.audioFile != nil || s.eventFile != nil {
        s.consecutiveWriteFailures += 1
        if s.consecutiveWriteFailures >= 3 {
          print("[AudioRecorder] Too many write failures — stopping file writes")
          s.audioFile = nil
          s.eventFile = nil
          writesDisabled = true
        }
      }
      return Levels(db: db, peakDB: peakDB, spectralScore: features.spectralScore, writesDisabled: writesDisabled)
    }
  }

  private static func rmsDB(_ buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return -160.0 }
    let frameLength = UInt32(buffer.frameLength)
    var sum: Float = 0
    for i in 0..<Int(frameLength) {
      sum += channelData[i] * channelData[i]
    }
    let rms = sqrt(sum / Float(frameLength))
    let db = 20 * log10(max(rms, 1e-10))
    return db
  }

  /// Peak level (0 dBFS = full scale) of the buffer. Better than RMS for
  /// impulsive sounds like snoring, where the perceptual loudness is driven
  /// by sharp peaks rather than average energy.
  private static func peakDB(_ buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return -160.0 }
    let frameLength = Int(buffer.frameLength)
    var peak: Float = 0
    for i in 0..<frameLength {
      let absVal = abs(channelData[i])
      if absVal > peak {
        peak = absVal
      }
    }
    let db = 20 * log10(max(peak, 1e-10))
    return db
  }
}
