import AudioEngine
import AVFoundation
import Foundation
import Models

/// Loads waveform sample buffers for snore events: reads an existing event
/// clip when available, otherwise exports the event span from the full
/// session recording first. Generation runs off the main thread.
@MainActor
@Observable
final class WaveformLoader {
  var samples: [Float] = []
  var isLoading = false

  func load(for event: SnoreEvent?, sessionAudioURL: URL?, sessionStart: Date) {
    guard let event else {
      samples = []
      isLoading = false
      return
    }
    // Try event clip URL first (run off-main so large files don't block UI)
    if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
      isLoading = true
      let duration = event.snoreDuration
      Task.detached(priority: .userInitiated) {
        let samples = WaveformGenerator.generateSamples(from: url, maxDuration: duration)
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
      // Destructure Sendable fields before crossing into the extractor — a
      // SwiftData @Model class cannot be sent across isolation boundaries.
      let eventID = event.id
      let eventTimestamp = event.timestamp
      let eventSnoreDuration = event.snoreDuration
      let eventBursts = event.bursts
      let totalDuration = AVURLAsset(url: sessionAudioURL).duration.seconds
      let result = await AudioClipExtractor.extractSingleClip(
        eventID: eventID,
        eventTimestamp: eventTimestamp,
        eventSnoreDuration: eventSnoreDuration,
        bursts: eventBursts,
        sessionURL: sessionAudioURL,
        sessionStart: sessionStart,
        totalDuration: totalDuration,
        padding: 0,
        outputDirectory: FileManager.default.temporaryDirectory
      )
      guard let result else {
        await MainActor.run {
          self.samples = []
          self.isLoading = false
        }
        return
      }
      let samples = await Task.detached(priority: .userInitiated) {
        WaveformGenerator.generateSamples(from: result.clipURL)
      }.value
      await MainActor.run {
        self.samples = samples
        self.isLoading = false
      }
    }
  }
}
