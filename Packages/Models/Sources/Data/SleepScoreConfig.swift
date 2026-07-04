import Foundation

/// Tunable parameters for the sleep score formula.
///
/// All properties have defaults that match the current formula. The defaults are
/// intentionally strict: severe snoring nights should score low, and very
/// fragmented sleep is penalized heavily.
///
/// The score is computed as:
///
///     score = max(minScore,
///                 maxScore
///                 - snoringPenalty
///                 - eventsPenalty
///                 - intensityPenalty
///                 - sleepTalkingPenalty
///                 - stagePenalty
///                 - shortSleepPenalty
///                 - longSleepPenalty)
public struct SleepScoreConfig: Codable, Sendable, Hashable {
  public var maxScore: Int
  public var minScore: Int

  // MARK: - Snoring duration penalty

  public var snoringMultiplier: Double
  public var snoringPenaltyCap: Int

  // MARK: - Events-per-hour penalty

  public var eventsPerHourMultiplier: Double
  public var eventsPenaltyCap: Int

  // MARK: - Intensity penalty

  public var lightIntensityMultiplier: Double
  public var loudIntensityMultiplier: Double
  public var epicIntensityMultiplier: Double
  public var intensityPenaltyCap: Int

  // MARK: - Sleep talking penalty

  public var sleepTalkingPercentageMultiplier: Double
  public var sleepTalkingFrequencyMultiplier: Double
  public var sleepTalkingPenaltyCap: Int

  // MARK: - Sleep stage penalty

  public var deepPctTarget: Double
  public var deepDeficitMultiplier: Double

  public var remPctTarget: Double
  public var remDeficitMultiplier: Double

  public var awakePctTarget: Double
  public var awakeExcessMultiplier: Double

  public var stagePenaltyCap: Int

  // MARK: - Sleep duration penalty

  /// Sessions shorter than this are not penalized for short sleep.
  /// Prevents test sessions and short naps from getting a large penalty.
  public var shortSleepMinimumSessionHours: Double
  /// Sleep duration below this threshold starts incurring a penalty.
  public var shortSleepThresholdHours: Double
  /// Penalty per hour of sleep below `shortSleepThresholdHours`.
  public var shortSleepMultiplier: Double
  public var shortSleepPenaltyCap: Int

  /// Sleep duration above this threshold starts incurring a small penalty.
  public var longSleepThresholdHours: Double
  /// Penalty per hour of sleep above `longSleepThresholdHours`.
  public var longSleepMultiplier: Double
  public var longSleepPenaltyCap: Int

  public init(
    maxScore: Int = 100,
    minScore: Int = 0,
    snoringMultiplier: Double = 0.85,
    snoringPenaltyCap: Int = 75,
    eventsPerHourMultiplier: Double = 2.5,
    eventsPenaltyCap: Int = 25,
    lightIntensityMultiplier: Double = 10.0,
    loudIntensityMultiplier: Double = 20.0,
    epicIntensityMultiplier: Double = 40.0,
    intensityPenaltyCap: Int = 30,
    sleepTalkingPercentageMultiplier: Double = 0.35,
    sleepTalkingFrequencyMultiplier: Double = 0.8,
    sleepTalkingPenaltyCap: Int = 15,
    deepPctTarget: Double = 15.0,
    deepDeficitMultiplier: Double = 0.6,
    remPctTarget: Double = 18.0,
    remDeficitMultiplier: Double = 0.4,
    awakePctTarget: Double = 8.0,
    awakeExcessMultiplier: Double = 1.0,
    stagePenaltyCap: Int = 15,
    shortSleepMinimumSessionHours: Double = 3.0,
    shortSleepThresholdHours: Double = 6.0,
    shortSleepMultiplier: Double = 2.0,
    shortSleepPenaltyCap: Int = 8,
    longSleepThresholdHours: Double = 9.0,
    longSleepMultiplier: Double = 1.0,
    longSleepPenaltyCap: Int = 5
  ) {
    self.maxScore = maxScore
    self.minScore = minScore
    self.snoringMultiplier = snoringMultiplier
    self.snoringPenaltyCap = snoringPenaltyCap
    self.eventsPerHourMultiplier = eventsPerHourMultiplier
    self.eventsPenaltyCap = eventsPenaltyCap
    self.lightIntensityMultiplier = lightIntensityMultiplier
    self.loudIntensityMultiplier = loudIntensityMultiplier
    self.epicIntensityMultiplier = epicIntensityMultiplier
    self.intensityPenaltyCap = intensityPenaltyCap
    self.sleepTalkingPercentageMultiplier = sleepTalkingPercentageMultiplier
    self.sleepTalkingFrequencyMultiplier = sleepTalkingFrequencyMultiplier
    self.sleepTalkingPenaltyCap = sleepTalkingPenaltyCap
    self.deepPctTarget = deepPctTarget
    self.deepDeficitMultiplier = deepDeficitMultiplier
    self.remPctTarget = remPctTarget
    self.remDeficitMultiplier = remDeficitMultiplier
    self.awakePctTarget = awakePctTarget
    self.awakeExcessMultiplier = awakeExcessMultiplier
    self.stagePenaltyCap = stagePenaltyCap
    self.shortSleepMinimumSessionHours = shortSleepMinimumSessionHours
    self.shortSleepThresholdHours = shortSleepThresholdHours
    self.shortSleepMultiplier = shortSleepMultiplier
    self.shortSleepPenaltyCap = shortSleepPenaltyCap
    self.longSleepThresholdHours = longSleepThresholdHours
    self.longSleepMultiplier = longSleepMultiplier
    self.longSleepPenaltyCap = longSleepPenaltyCap
  }

  /// Baked-in defaults that reproduce the current sleep score formula.
  public static let `default` = SleepScoreConfig()
}
