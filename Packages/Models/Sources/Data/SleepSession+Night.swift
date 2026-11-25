import Foundation
public import SleepCore

/// Stored models → the shared night values (SleepGuardShared's `Night`,
/// `NightEvent`). The night rules (episodes, snoring duration, score inputs,
/// stage stats) run on those values, so SleepGuard and SleepGuardUIKitWay
/// compute the same numbers from one implementation.
///
/// Reads `events` (faults the relationship), like the properties it replaced.
public extension SleepSession {
  var night: Night {
    Night(
      id: id,
      start: startDate,
      // An unfinished session has no length (it scores the maximum).
      end: max(endDate ?? startDate, startDate),
      averageDB: averageDB,
      peakDB: peakDB,
      events: (events ?? []).map(\.nightEvent),
      recordingGaps: recordingGaps ?? [],
      sleepStages: sleepStageSegments ?? [],
      endReason: terminationReason == "low_battery" ? .lowBattery : .stopped)
  }

  /// What the statistics rules (SleepCore) need about this night: the cached
  /// score and snoring time where there are ones, as the views always showed.
  /// Reads `events`: build it only for the nights a screen shows.
  var nightSummary: NightSummary {
    let night = night
    return NightSummary(
      id: id, start: night.start, end: night.end, score: sleepScore, snoringDuration: snoringDuration,
      eventCount: night.eventCount, loudestIntensity: night.loudestIntensity)
  }

  /// Start, end, score and snoring time from the cached fields, without
  /// reading `events` (faulting them has crashed in production). For choosing
  /// nights (dashboard, trend, which day): `eventCount` is 0 and
  /// `loudestIntensity` is `nil`, so don't show those from it.
  var summaryWithoutEvents: NightSummary {
    NightSummary(
      id: id, start: startDate, end: max(endDate ?? startDate, startDate), score: sleepScore,
      snoringDuration: snoringDuration, eventCount: 0)
  }

  /// The stored events by id, to map shared episodes back to models.
  internal var eventModelsByID: [UUID: SnoreEvent] {
    Dictionary((events ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }
}

extension SnoreEvent {
  var nightEvent: NightEvent {
    NightEvent(
      id: id,
      start: timestamp,
      // `snoreDuration`: the span, or the burst sum for legacy events stored with 0.
      duration: snoreDuration,
      category: category,
      intensity: intensity,
      averageDB: averageDB,
      peakDB: peakDB,
      averageConfidence: averageConfidence,
      bursts: bursts ?? [],
      clipFileName: audioFileURL)
  }
}
