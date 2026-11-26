import Foundation
import Models
import SleepAudioKit
import SleepStore

/// Loads waveform sample buffers for snore events: reads an existing event
/// clip when available, otherwise exports the event span from the full
/// session recording first. Generation runs off the main thread.
@MainActor
@Observable
final class WaveformLoader {
  var samples: [Float] = []
  var isLoading = false

  func load(for event: NightEventRecord?, sessionAudioURL: URL?, sessionStart: Date) {
    guard let event else {
      samples = []
      isLoading = false
      return
    }
    // Try event clip URL first (run off-main so large files don't block UI)
    if let url = AudioFileURLResolver.resolve(event.clipFileName) {
      isLoading = true
      let duration = event.snoreDuration
      Task(priority: .userInitiated) {
        let samples = await ClipWaveform().waveform(of: url, duration: duration)
        await MainActor.run {
          self.samples = samples
          self.isLoading = false
        }
      }
      return
    }
    // Fallback: generate from full session audio if available
    guard let sessionAudioURL else {
      samples = []
      isLoading = false
      return
    }
    isLoading = true
    Task(priority: .userInitiated) {
      // The event's Sendable fields, read here: a SwiftData @Model can't cross
      // into the extractor.
      let clipURL = FileManager.default.temporaryDirectory.appendingPathComponent("event_\(event.id.uuidString).m4a")
      guard await ClipExtractor.extract(event.clipSource, from: sessionAudioURL, nightStart: sessionStart, to: clipURL) else {
        await MainActor.run {
          self.samples = []
          self.isLoading = false
        }
        return
      }
      let samples = await ClipWaveform().waveform(of: clipURL, duration: nil)
      await MainActor.run {
        self.samples = samples
        self.isLoading = false
      }
    }
  }
}
