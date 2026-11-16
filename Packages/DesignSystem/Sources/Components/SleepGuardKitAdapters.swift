import Models
import SleepCore
import SwiftUI

// The shared design kit's components take plain values. These initializers
// build them from SleepGuard's stored models, with the signatures the old
// SleepGuard-only components had, so their call sites stay as they were.

public extension SessionStatsGrid {
  /// Duration, snoring share, snore time and events of `session`.
  init(session: SleepSession) {
    self.init(
      duration: session.totalDuration, snoringShare: session.snoringPercentage / 100,
      snoreTime: session.snoringDuration, eventCount: session.eventsCount)
  }
}

public extension SessionSummaryHeader {
  /// Length, score, snoring share and events of the night just recorded.
  init(session: SleepSession, scoreConfig: SleepScoreConfig) {
    self.init(
      duration: session.totalDuration, score: session.sleepScore(using: scoreConfig),
      snoringPercent: session.snoringPercentage, eventCount: session.eventsCount)
  }
}

public extension NightTimeline {
  /// The night's snoring episodes (merged, long enough to show) and its other
  /// events, its recording gaps, and its start and end. Reads `events`.
  init(session: SleepSession, showsTitle: Bool = true) {
    let episodes = session.displayableSnoringEpisodes.map {
      TimelineMark(start: $0.startTime, duration: $0.snoreDuration, category: .snoring, intensity: $0.intensity)
    }
    let others = (session.events ?? []).filter { $0.category != .snoring }.map {
      TimelineMark(start: $0.timestamp, duration: $0.snoreDuration, category: $0.category, intensity: $0.intensity)
    }
    self.init(
      start: session.startDate,
      end: session.endDate ?? session.startDate.addingTimeInterval(session.totalDuration),
      marks: (episodes + others).sorted { $0.start < $1.start },
      gaps: session.recordingGaps ?? [],
      eventCount: session.eventsCount,
      snoringDuration: session.snoringDuration,
      showsTitle: showsTitle)
  }
}

public extension EventRow {
  /// `displayDuration`: the episode's time when the row stands for one.
  init(event: SnoreEvent, displayDuration: TimeInterval?, onPlay: @escaping () -> Void, onShare: @escaping () -> Void) {
    self.init(
      start: event.timestamp, duration: displayDuration ?? event.snoreDuration, category: event.category,
      intensity: event.intensity, onPlay: onPlay, onShare: onShare)
  }
}

public extension EventCard {
  init(event: SnoreEvent, displayDuration: TimeInterval?, onPlay: @escaping () -> Void) {
    self.init(
      start: event.timestamp, duration: displayDuration ?? event.snoreDuration, category: event.category,
      intensity: event.intensity, onPlay: onPlay)
  }
}
