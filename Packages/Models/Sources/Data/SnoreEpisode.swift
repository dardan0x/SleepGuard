public import Foundation
public import SleepCore
public import SleepStore

/// A group of adjacent snoring events that are close enough in time
/// to be considered a single snoring episode.
///
/// The grouping and every number come from the shared `NightEpisode`
/// (SleepGuardShared), so this app and SleepGuardUIKitWay agree. This type
/// adds the stored `NightEventRecord`s, which screens need for playback and clips.
public struct SnoringEpisode: Identifiable {
  /// The shared value this episode stands for.
  public let episode: NightEpisode
  /// The same events as `episode.events`, as stored models, in time order.
  public let events: [NightEventRecord]

  /// `models` must contain every event of `episode`; extra ones are ignored.
  init(_ episode: NightEpisode, models: [UUID: NightEventRecord]) {
    self.episode = episode
    events = episode.events.compactMap { models[$0.id] }
  }

  public var id: UUID {
    episode.id
  }

  public var startTime: Date {
    episode.start
  }

  public var duration: TimeInterval {
    episode.duration
  }

  public var intensity: SnoreIntensity {
    episode.intensity
  }

  public var snoreDuration: TimeInterval {
    episode.snoreDuration
  }

  /// Actual detector-classified snoring duration, excluding melody gaps
  /// where the microphone was paused.
  public var detectedDuration: TimeInterval {
    episode.measuredDuration
  }

  public var representativeEvent: NightEventRecord? {
    events.first { $0.id == episode.representativeEvent.id }
  }

  public var peakDB: Double {
    episode.peakDB
  }

  public var averageDB: Double {
    episode.averageDB
  }

  /// Renderable segments for the timeline. Uses bursts when available so
  /// melody gaps are not drawn as solid snoring blocks.
  public var detectedSegments: [(id: UUID, start: Date, duration: TimeInterval, intensity: SnoreIntensity)] {
    let hasBursts = events.contains { !$0.bursts.isEmpty }
    var segments: [(UUID, Date, TimeInterval, SnoreIntensity)] = []
    if hasBursts {
      for event in events {
        for burst in event.bursts {
          segments.append((
            id: UUID(),
            start: event.start.addingTimeInterval(burst.startOffset),
            duration: burst.duration,
            intensity: event.intensity))
        }
      }
    } else {
      for event in events {
        segments.append((
          id: UUID(),
          start: event.start,
          duration: event.snoreDuration,
          intensity: event.intensity))
      }
    }
    return segments.sorted(by: { $0.1 < $1.1 })
  }
}
