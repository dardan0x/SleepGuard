import AudioEngine
import Models

extension SnoreEvent {
  /// The event as the audio layer reads it (AudioEngine doesn't know `SnoreEvent`).
  /// Read on the main actor before crossing into the extractor: a SwiftData
  /// `@Model` can't be sent across isolation boundaries.
  var clipSource: ClipSource {
    ClipSource(id: id, timestamp: timestamp, snoreDuration: snoreDuration, bursts: bursts)
  }
}
