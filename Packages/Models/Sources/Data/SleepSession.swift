import Foundation
import SleepCore
import SwiftData

@Model
public final class SleepSession {
  @Attribute(.unique) public var id: UUID
  public var startDate: Date
  public var endDate: Date?
  /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
  /// Values are relative and vary by microphone sensitivity and device distance.
  public var averageDB: Double
  /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
  public var peakDB: Double
  public var audioFileURL: String?

  /// Full session raw audio file preserved for future re-processing.
  /// When detection thresholds or debounce logic change, old sessions
  /// can be re-analysed from this file instead of using baked event data.
  public var rawAudioFileURL: String?

  /// Classification sample log (JSON) recorded at ~20 Hz during the session.
  /// Contains every sample's dB, spectral score, snore confidence, and state.
  /// Allows instant re-processing with different debounce or threshold values
  /// without re-running audio analysis.
  public var rawLogFileURL: String?

  @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session)
  public var events: [SnoreEvent]?

  /// Intervals when the microphone was paused (e.g. during Snore Interrupter playback).
  /// Used to compute monitoredDuration and surface detection blind spots in the UI.
  public var recordingGaps: [RecordingGap]?

  /// Why the session ended early (e.g. "low_battery"). Set when the app force-saves
  /// to preserve data before the phone shuts down. nil for normal user-stopped sessions.
  public var terminationReason: String?

  /// Optional sleep stage segments sourced from Apple Health (Apple Watch).
  /// nil when no Watch data is available for this session.
  public var sleepStageSegments: [SleepStageSegment]?

  /// Cached values to avoid faulting the `events` relationship on app reopen.
  /// Set when the session is saved; used by `sleepScore` and `snoringDuration`.
  /// Written only by `refreshCachedScore(using:)`.
  public var hasCachedScore = false
  public var cachedSleepScore = 0
  public var cachedSnoringDuration: TimeInterval = 0
  /// `SleepScore.cacheVersion(for:)` of the formula that produced the cached
  /// values. Empty for sessions cached before F22-T3, so they count as stale.
  public var cachedScoreVersion = ""

  /// SleepCore's rule (`Night.minimumSaveDuration`).
  public static var minimumSaveDuration: TimeInterval {
    Night.minimumSaveDuration
  }

  public init(
    id: UUID = UUID(),
    startDate: Date,
    endDate: Date? = nil,
    averageDB: Double = 0,
    peakDB: Double = 0,
    audioFileURL: String? = nil,
    rawAudioFileURL: String? = nil,
    rawLogFileURL: String? = nil)
  {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.audioFileURL = audioFileURL
    self.rawAudioFileURL = rawAudioFileURL
    self.rawLogFileURL = rawLogFileURL
  }

  /// Derived from raw data. Computed on demand so formula changes retroactively affect all sessions.
  public var totalDuration: TimeInterval {
    endDate?.timeIntervalSince(startDate) ?? 0
  }

  /// Total duration of all recording gaps (microphone-paused intervals).
  public var gapsDuration: TimeInterval {
    recordingGaps?.reduce(0) { $0 + $1.duration } ?? 0
  }

  public var snoringDuration: TimeInterval {
    if hasCachedScore {
      return cachedSnoringDuration
    }
    // Events plus recording gaps where snoring resumed: the shared rule.
    return night.snoringDuration
  }

  /// Total duration of sleep talking events.
  public var sleepTalkingDuration: TimeInterval {
    night.sleepTalkingDuration
  }

  /// Sleep talking events count.
  public var sleepTalkingEvents: Int {
    night.sleepTalkingEvents.count
  }

  /// Sleep talking duration as a percentage of total session time.
  public var sleepTalkingPercentage: Double {
    totalDuration > 0 ? (sleepTalkingDuration / totalDuration) * 100 : 0
  }

  /// Sleep talking events per hour.
  public var sleepTalkingEventsPerHour: Double {
    totalDuration > 0 ? Double(sleepTalkingEvents) / (totalDuration / 3600) : 0
  }

  /// Total duration of events matching a specific sound category.
  public func duration(for category: SoundCategory) -> TimeInterval {
    events?.filter { $0.category == category }.reduce(0) { $0 + $1.snoreDuration } ?? 0
  }

  /// Duration during which the microphone was actually active and listening.
  public var monitoredDuration: TimeInterval {
    max(0, totalDuration - gapsDuration)
  }

  public var snoringPercentage: Double {
    totalDuration > 0 ? (snoringDuration / totalDuration) * 100 : 0
  }

  /// Groups adjacent snoring events within a 5-minute gap into episodes
  /// (shared `SnoringEpisodes` rule). Reduces visual clutter and false-positive
  /// event counts while preserving total snoring duration.
  public var snoringEpisodes: [SnoringEpisode] {
    let models = eventModelsByID
    return SnoringEpisodes.all(in: night.events).map { SnoringEpisode($0, models: models) }
  }

  /// Episodes with enough total snoring duration to be worth displaying (3 s,
  /// shared rule). Hides micro-episodes that are likely false positives while
  /// still counting them in `snoringDuration`.
  public var displayableSnoringEpisodes: [SnoringEpisode] {
    let models = eventModelsByID
    return SnoringEpisodes.displayable(in: night.events).map { SnoringEpisode($0, models: models) }
  }

  /// The events to play when a list row for `event` is tapped: a snoring row
  /// keyed by its episode's representative event plays the whole episode in
  /// time order, so the player total matches the row; anything else plays alone.
  public func episodePlaybackEvents(for event: SnoreEvent) -> [SnoreEvent] {
    let models = eventModelsByID
    return SnoringEpisodes.playbackEvents(for: event.nightEvent, in: night.events).compactMap { models[$0.id] }
  }

  /// Displayable snoring episodes plus every non-snoring event (shared rule).
  public var eventsCount: Int {
    night.eventCount
  }

  public var eventsPerHour: Double {
    totalDuration > 0 ? Double(eventsCount) / (totalDuration / 3600) : 0
  }

  /// Percentage breakdown of sleep stages when Watch data is available.
  public var stageStats: StageStats? {
    night.stageStats
  }

  public var sleepScore: Int {
    if hasCachedScore {
      return cachedSleepScore
    }
    return sleepScore(using: .default)
  }

  /// Computes the sleep score using the supplied configuration.
  ///
  /// This method always reads events and recomputes; it does not use the
  /// cached score. Callers that iterate many sessions should use the
  /// `sleepScore` property instead to avoid SwiftData relationship faulting.
  public func sleepScore(using config: SleepScoreConfig) -> Int {
    SleepScore.compute(sleepInputs, config: config)
  }

  /// The score formula's inputs, read from events, gaps, and stages.
  ///
  /// Reads `events` (faults the relationship). `snoringDuration` returns the
  /// cached value when one exists, so inputs match what lists display.
  public var sleepInputs: SleepInputs {
    var inputs = night.scoreInputs
    // The cached value when there is one, so the score matches what lists show.
    inputs.snoringDuration = snoringDuration
    return inputs
  }
}
