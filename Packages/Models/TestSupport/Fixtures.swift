public import Foundation
public import Models
public import SleepCore

public extension NightRecord {
  /// A finished session of `hours` length starting at `start`.
  static func fixture(start: Date, hours: Double = 8) -> NightRecord {
    NightRecord(start: start, end: start.addingTimeInterval(hours * 3600))
  }
}

public extension NightEventRecord {
  static func fixture(
    at timestamp: Date,
    duration: TimeInterval = 60,
    intensity: SnoreIntensity = .light,
    category: SoundCategory = .snoring,
    averageDB: Double = -35,
    peakDB: Double = -25,
    bursts: [SnoreBurst] = []) -> NightEventRecord
  {
    NightEventRecord.make(from: NightEvent(
      start: timestamp, duration: duration, category: category, intensity: intensity,
      averageDB: averageDB, peakDB: peakDB, bursts: bursts))
  }
}
