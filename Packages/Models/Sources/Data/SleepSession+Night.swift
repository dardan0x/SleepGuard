import Foundation
import SleepCore

/// Stored models → the shared night values (SleepGuardShared's `Night`,
/// `NightEvent`). The night rules (episodes, snoring duration, score inputs,
/// stage stats) run on those values, so SleepGuard and SleepGuardUIKitWay
/// compute the same numbers from one implementation.
///
/// Reads `events` (faults the relationship), like the properties it replaced.
extension SleepSession {
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

  /// The stored events by id, to map shared episodes back to models.
  var eventModelsByID: [UUID: SnoreEvent] {
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
