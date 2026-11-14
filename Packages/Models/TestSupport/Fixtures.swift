import Foundation
import Models
import SleepCore

public extension SleepSession {
  /// A finished session of `hours` length starting at `start`.
  static func fixture(start: Date, hours: Double = 8) -> SleepSession {
    SleepSession(startDate: start, endDate: start.addingTimeInterval(hours * 3600))
  }
}

public extension SnoreEvent {
  static func fixture(
    at timestamp: Date,
    duration: TimeInterval = 60,
    intensity: SnoreIntensity = .light,
    category: SoundCategory = .snoring,
    averageDB: Double = -35,
    peakDB: Double = -25,
    bursts: [SnoreBurst]? = nil) -> SnoreEvent
  {
    SnoreEvent(
      timestamp: timestamp,
      category: category,
      intensity: intensity,
      averageDB: averageDB,
      peakDB: peakDB,
      bursts: bursts,
      duration: duration)
  }
}
