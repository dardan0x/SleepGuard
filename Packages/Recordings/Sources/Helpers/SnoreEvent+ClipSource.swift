import Models
import SleepAudioKit

extension NightEventRecord {
  /// The event as SleepGuardShared's `ClipExtractor` reads it.
  /// Read on the main actor before crossing into the extractor: a SwiftData
  /// `@Model` can't be sent across isolation boundaries.
  var clipSource: ClipExtractor.Source {
    ClipExtractor.Source(id: id, start: start, snoreDuration: snoreDuration, bursts: bursts)
  }
}
