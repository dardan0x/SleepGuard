import Foundation

/// Everything the sleep score formula reads, as plain values.
///
/// `SleepSession.sleepInputs` builds this from the stored session (events,
/// gaps, stages). Keeping the formula on a value type means it can be tested
/// and reused without a SwiftData `ModelContainer`.
public struct SleepInputs: Sendable, Equatable {
  /// Session length (end − start), including recording gaps.
  public var totalDuration: TimeInterval
  /// Snoring time used for the snoring percentage: detected events plus
  /// recording gaps where snoring resumed (see `SleepSession.snoringDuration`).
  public var snoringDuration: TimeInterval
  /// Displayable snoring episodes (≥ 3 s after merging events 5 min apart).
  public var snoringEpisodeCount: Int
  /// Measured snoring (sum of bursts) per intensity. Melody gaps are excluded,
  /// since no intensity was measured during them.
  public var quietSnoring: TimeInterval
  public var lightSnoring: TimeInterval
  public var loudSnoring: TimeInterval
  public var epicSnoring: TimeInterval
  public var sleepTalkingCount: Int
  public var sleepTalkingDuration: TimeInterval
  /// Sleep stage percentages from Watch/HealthKit, when available.
  public var stages: StageStats?

  public init(
    totalDuration: TimeInterval,
    snoringDuration: TimeInterval = 0,
    snoringEpisodeCount: Int = 0,
    quietSnoring: TimeInterval = 0,
    lightSnoring: TimeInterval = 0,
    loudSnoring: TimeInterval = 0,
    epicSnoring: TimeInterval = 0,
    sleepTalkingCount: Int = 0,
    sleepTalkingDuration: TimeInterval = 0,
    stages: StageStats? = nil)
  {
    self.totalDuration = totalDuration
    self.snoringDuration = snoringDuration
    self.snoringEpisodeCount = snoringEpisodeCount
    self.quietSnoring = quietSnoring
    self.lightSnoring = lightSnoring
    self.loudSnoring = loudSnoring
    self.epicSnoring = epicSnoring
    self.sleepTalkingCount = sleepTalkingCount
    self.sleepTalkingDuration = sleepTalkingDuration
    self.stages = stages
  }

  /// All measured snoring, any intensity: the denominator for intensity ratios.
  var detectedSnoring: TimeInterval {
    quietSnoring + lightSnoring + loudSnoring + epicSnoring
  }
}

/// The sleep score formula. A pure function of `SleepInputs` and
/// `SleepScoreConfig`; see `SleepScoreConfig` for the shape of the formula.
///
/// The coefficients are hand-tuned product heuristics, not a clinical measure.
/// Only the sleep-stage targets come from the sleep literature.
public enum SleepScore {
  public static func compute(_ inputs: SleepInputs, config: SleepScoreConfig) -> Int {
    let duration = inputs.totalDuration
    guard duration > 0 else {
      return config.maxScore
    }
    let hours = duration / 3600

    let snoringPercentage = (inputs.snoringDuration / duration) * 100
    let snoringPenalty = min(Int(snoringPercentage * config.snoringMultiplier), config.snoringPenaltyCap)
    let eventsPenalty = min(
      Int(Double(inputs.snoringEpisodeCount) / hours * config.eventsPerHourMultiplier),
      config.eventsPenaltyCap)

    return max(config.minScore, config.maxScore
      - snoringPenalty
      - eventsPenalty
      - intensityPenalty(inputs, config: config)
      - sleepTalkingPenalty(inputs, config: config)
      - stagePenalty(inputs.stages, config: config)
      - shortSleepPenalty(hours: hours, config: config)
      - longSleepPenalty(hours: hours, config: config))
  }

  /// Intensity ratios use measured snoring as the denominator: there is no
  /// intensity data during melody gaps, so the gap time doesn't add to this penalty.
  private static func intensityPenalty(_ inputs: SleepInputs, config: SleepScoreConfig) -> Int {
    let detected = inputs.detectedSnoring
    guard detected > 0 else { return 0 }
    let weighted = inputs.lightSnoring / detected * config.lightIntensityMultiplier
      + inputs.loudSnoring / detected * config.loudIntensityMultiplier
      + inputs.epicSnoring / detected * config.epicIntensityMultiplier
    return min(Int(weighted), config.intensityPenaltyCap)
  }

  /// Weighted about half as much as snoring: less severe, but it still fragments sleep.
  private static func sleepTalkingPenalty(_ inputs: SleepInputs, config: SleepScoreConfig) -> Int {
    guard inputs.sleepTalkingCount > 0 else { return 0 }
    let percentage = (inputs.sleepTalkingDuration / inputs.totalDuration) * 100
    let perHour = Double(inputs.sleepTalkingCount) / (inputs.totalDuration / 3600)
    return min(
      Int(percentage * config.sleepTalkingPercentageMultiplier + perHour * config.sleepTalkingFrequencyMultiplier),
      config.sleepTalkingPenaltyCap)
  }

  /// Only applies with Watch/HealthKit data. Targets: deep ≥ 15%, REM ≥ 18%, awake ≤ 8%.
  private static func stagePenalty(_ stages: StageStats?, config: SleepScoreConfig) -> Int {
    guard let stages else { return 0 }
    let deepDeficit = max(0, (config.deepPctTarget - stages.deepPct) * config.deepDeficitMultiplier)
    let remDeficit = max(0, (config.remPctTarget - stages.remPct) * config.remDeficitMultiplier)
    let awakeExcess = max(0, (stages.awakePct - config.awakePctTarget) * config.awakeExcessMultiplier)
    return min(Int(deepDeficit + remDeficit + awakeExcess), config.stagePenaltyCap)
  }

  /// Sessions under `shortSleepMinimumSessionHours` (naps, tests) aren't penalized.
  private static func shortSleepPenalty(hours: Double, config: SleepScoreConfig) -> Int {
    guard hours >= config.shortSleepMinimumSessionHours else { return 0 }
    let deficit = max(0, config.shortSleepThresholdHours - hours)
    return min(Int(deficit * config.shortSleepMultiplier), config.shortSleepPenaltyCap)
  }

  private static func longSleepPenalty(hours: Double, config: SleepScoreConfig) -> Int {
    let excess = max(0, hours - config.longSleepThresholdHours)
    return min(Int(excess * config.longSleepMultiplier), config.longSleepPenaltyCap)
  }
}
