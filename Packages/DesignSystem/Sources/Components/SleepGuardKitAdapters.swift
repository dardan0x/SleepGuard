public import Models
public import SleepCore
public import SwiftUI
public import SleepStore
public import SleepGuardDesignKit
public import SleepGuardContentKit

// The shared design kit's components take plain values. These initializers
// build them from SleepGuard's stored models, with the signatures the old
// SleepGuard-only components had, so their call sites stay as they were.

public extension SessionStatsGrid {
  /// Duration, snoring share, snore time and events of `session`.
  init(session: NightRecord) {
    self.init(
      duration: session.totalDuration, snoringShare: session.snoringPercentage / 100,
      snoreTime: session.snoringDuration, eventCount: session.eventCount)
  }
}

public extension SessionSummaryHeader {
  /// Length, score, snoring share and events of the night just recorded.
  init(session: NightRecord, scoreConfig: SleepScoreConfig) {
    self.init(
      duration: session.totalDuration, score: session.sleepScore(using: scoreConfig),
      snoringPercent: session.snoringPercentage, eventCount: session.eventCount)
  }
}

public extension NightTimeline {
  /// The night's snoring episodes (merged, long enough to show) and its other
  /// events, its recording gaps, and its start and end. Reads `events`.
  init(session: NightRecord, showsTitle: Bool = true) {
    let episodes = session.displayableSnoringEpisodes.map {
      TimelineMark(start: $0.startTime, duration: $0.snoreDuration, category: .snoring, intensity: $0.intensity)
    }
    let others = session.events.filter { $0.category != .snoring }.map {
      TimelineMark(start: $0.start, duration: $0.snoreDuration, category: $0.category, intensity: $0.intensity)
    }
    self.init(
      start: session.start,
      end: session.end,
      marks: (episodes + others).sorted { $0.start < $1.start },
      gaps: session.recordingGaps,
      eventCount: session.eventCount,
      snoringDuration: session.snoringDuration,
      showsTitle: showsTitle)
  }
}

public extension EventRow {
  /// `displayDuration`: the episode's time when the row stands for one.
  init(event: NightEventRecord, displayDuration: TimeInterval?, onPlay: @escaping () -> Void, onShare: @escaping () -> Void) {
    self.init(
      start: event.start, duration: displayDuration ?? event.snoreDuration, category: event.category,
      intensity: event.intensity, onPlay: onPlay, onShare: onShare)
  }
}

public extension EventCard {
  init(event: NightEventRecord, displayDuration: TimeInterval?, onPlay: @escaping () -> Void) {
    self.init(
      start: event.start, duration: displayDuration ?? event.snoreDuration, category: event.category,
      intensity: event.intensity, onPlay: onPlay)
  }
}

public extension PlayerClip {
  /// A stored event as the shared player's clip.
  init(event: NightEventRecord) {
    self.init(id: event.id, start: event.start, duration: event.snoreDuration, category: event.category, intensity: event.intensity)
  }
}
