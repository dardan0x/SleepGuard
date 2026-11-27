public import Foundation
public import SleepCore
public import SleepStore

// SleepGuard's reads on the shared night records (SleepGuardShared's
// SleepStore, the same records SleepGuardUIKitWay stores). The numbers come
// from SleepCore's night rules on `night`; the stored summary (`score`,
// `snoringDuration`, `eventCount`) is what lists show without reading events.

public extension NightRecord {
  /// When a stopped night is worth saving (SleepCore's `SaveRules`). Debug
  /// builds take 2 minutes so a night can be tried at a desk.
  static var saveRules: SaveRules {
    #if DEBUG
    SaveRules(minimumDuration: 120)
    #else
    .standard
    #endif
  }

  static var minimumSaveDuration: TimeInterval {
    saveRules.minimumDuration
  }

  /// Whether the night has a summary (it is saved, or stopped and summarized).
  var hasSummary: Bool {
    !scoreVersion.isEmpty
  }

  var totalDuration: TimeInterval {
    max(0, end.timeIntervalSince(start))
  }

  /// Total duration of all recording gaps (microphone-paused intervals).
  var gapsDuration: TimeInterval {
    recordingGaps.reduce(0) { $0 + $1.duration }
  }

  /// Duration during which the microphone was actually active and listening.
  var monitoredDuration: TimeInterval {
    max(0, totalDuration - gapsDuration)
  }

  var snoringPercentage: Double {
    totalDuration > 0 ? (snoringDuration / totalDuration) * 100 : 0
  }

  var sleepTalkingDuration: TimeInterval {
    night.sleepTalkingDuration
  }

  var sleepTalkingEvents: Int {
    night.sleepTalkingEvents.count
  }

  var sleepTalkingPercentage: Double {
    totalDuration > 0 ? (sleepTalkingDuration / totalDuration) * 100 : 0
  }

  var sleepTalkingEventsPerHour: Double {
    totalDuration > 0 ? Double(sleepTalkingEvents) / (totalDuration / 3600) : 0
  }

  /// Total duration of events matching a specific sound category.
  func duration(for category: SoundCategory) -> TimeInterval {
    events.filter { $0.category == category }.reduce(0) { $0 + $1.snoreDuration }
  }

  var eventsPerHour: Double {
    totalDuration > 0 ? Double(eventCount) / (totalDuration / 3600) : 0
  }

  /// Percentage breakdown of sleep stages when Watch data is available.
  var stageStats: StageStats? {
    night.stageStats
  }

  /// The score with `config`, recomputed from the events (not the stored one).
  func sleepScore(using config: SleepScoreConfig) -> Int {
    night.summary(using: config).score
  }

  /// Adjacent snoring events grouped into episodes (shared `SnoringEpisodes`).
  var snoringEpisodes: [SnoringEpisode] {
    let models = eventModelsByID
    return SnoringEpisodes.all(in: night.events).map { SnoringEpisode($0, models: models) }
  }

  /// Episodes with enough snoring to be worth displaying (shared rule).
  var displayableSnoringEpisodes: [SnoringEpisode] {
    let models = eventModelsByID
    return SnoringEpisodes.displayable(in: night.events).map { SnoringEpisode($0, models: models) }
  }

  /// The events to play when a list row for `event` is tapped: a snoring row
  /// keyed by its episode's representative event plays the whole episode in
  /// time order; anything else plays alone.
  func episodePlaybackEvents(for event: NightEventRecord) -> [NightEventRecord] {
    let models = eventModelsByID
    return SnoringEpisodes.playbackEvents(for: event.event, in: night.events).compactMap { models[$0.id] }
  }

  /// The night's raw recording (`RawRecording`), when it was kept and is
  /// still in the clips folder.
  var rawAudioFileName: String? {
    let name = RawRecording.audioFileName(for: id)
    return AudioFileURLResolver.resolve(name) != nil ? name : nil
  }

  /// The raw recording's sample log, when it is still in the clips folder.
  var rawLogFileName: String? {
    let name = RawRecording.logFileName(for: id)
    return AudioFileURLResolver.resolve(name) != nil ? name : nil
  }

  /// The stored events by id, to map shared episodes back to records.
  internal var eventModelsByID: [UUID: NightEventRecord] {
    Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }
}

public extension NightEventRecord {
  /// Event-span duration including natural breathing pauses; the burst sum
  /// for events stored without one.
  var snoreDuration: TimeInterval {
    duration > 0 ? duration : bursts.reduce(0) { $0 + $1.duration }
  }
}
