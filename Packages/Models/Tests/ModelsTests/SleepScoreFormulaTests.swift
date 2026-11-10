import Foundation
import Testing
@testable import Models

/// `SleepScore.compute` on plain `SleepInputs`, with no SwiftData. Each case
/// shows its arithmetic with the default config, so a coefficient change points
/// at the exact number that moved. End-to-end scoring from stored sessions is
/// covered by `SleepScoreTests`.
struct SleepScoreFormulaTests {
  struct Case: Sendable, CustomTestStringConvertible {
    let name: String
    let inputs: SleepInputs
    let expected: Int
    var testDescription: String { name }
  }

  private static let hour: TimeInterval = 3600

  static let cases: [Case] = [
    Case(name: "zero duration → max", inputs: SleepInputs(totalDuration: 0), expected: 100),
    Case(name: "clean 8 h night", inputs: SleepInputs(totalDuration: 8 * hour), expected: 100),
    // Under the 3 h minimum, so no short-sleep penalty.
    Case(name: "2 h nap", inputs: SleepInputs(totalDuration: 2 * hour), expected: 100),
    // (6 − 4) × 2 = 4
    Case(name: "4 h night", inputs: SleepInputs(totalDuration: 4 * hour), expected: 96),
    // (11 − 9) × 1 = 2
    Case(name: "11 h night", inputs: SleepInputs(totalDuration: 11 * hour), expected: 98),
    // 15 h → 6 × 1 = 6, capped at 5
    Case(name: "15 h night caps long-sleep", inputs: SleepInputs(totalDuration: 15 * hour), expected: 95),
    // snoring 20% × 0.85 = 17; events 8/8 h × 2.5 = 2; light ratio 1 × 10 = 10 → 71
    Case(
      name: "20% light snoring, 8 episodes",
      inputs: SleepInputs(
        totalDuration: 8 * hour, snoringDuration: 1.6 * hour,
        snoringEpisodeCount: 8, lightSnoring: 1.6 * hour),
      expected: 71),
    // Quiet snoring adds no intensity penalty: 10% × 0.85 = 8 → 92
    Case(
      name: "10% quiet snoring",
      inputs: SleepInputs(
        totalDuration: 8 * hour, snoringDuration: 0.8 * hour, quietSnoring: 0.8 * hour),
      expected: 92),
    // snoring 100% × 0.85 = 85 → cap 75; epic 1 × 40 → cap 30; 100 − 105 → min 0
    Case(
      name: "100% epic snoring clamps to min",
      inputs: SleepInputs(
        totalDuration: 8 * hour, snoringDuration: 8 * hour,
        snoringEpisodeCount: 1, epicSnoring: 8 * hour),
      expected: 0),
    // events 400/8 h × 2.5 = 125 → cap 25
    Case(
      name: "events penalty caps",
      inputs: SleepInputs(totalDuration: 8 * hour, snoringEpisodeCount: 400),
      expected: 75),
    // Intensity uses measured snoring only: half light, half loud → 5 + 10 = 15.
    // snoringDuration 0 isolates the intensity penalty.
    Case(
      name: "mixed intensity ratio",
      inputs: SleepInputs(
        totalDuration: 8 * hour, lightSnoring: 0.5 * hour, loudSnoring: 0.5 * hour),
      expected: 85),
    // 1 h talking in 8 h: 12.5% × 0.35 = 4.375; 16/8 h × 0.8 = 1.6 → 5
    Case(
      name: "sleep talking",
      inputs: SleepInputs(
        totalDuration: 8 * hour, sleepTalkingCount: 16, sleepTalkingDuration: 1 * hour),
      expected: 95),
    // deep (15 − 10) × 0.6 = 3
    Case(
      name: "low deep sleep",
      inputs: SleepInputs(
        totalDuration: 8 * hour,
        stages: StageStats(awakePct: 8, remPct: 18, lightPct: 64, deepPct: 10)),
      expected: 97),
    // deep 15 × 0.6 = 9; REM 18 × 0.4 = 7.2; awake 42 × 1 = 42 → cap 15
    Case(
      name: "stage penalty caps",
      inputs: SleepInputs(
        totalDuration: 8 * hour,
        stages: StageStats(awakePct: 50, remPct: 0, lightPct: 50, deepPct: 0)),
      expected: 85),
  ]

  @Test(arguments: cases)
  func defaultConfig(_ testCase: Case) {
    #expect(SleepScore.compute(testCase.inputs, config: .default) == testCase.expected)
  }

  @Test(arguments: cases)
  func scoreStaysWithinBounds(_ testCase: Case) {
    let config = SleepScoreConfig.default
    let score = SleepScore.compute(testCase.inputs, config: config)
    #expect((config.minScore...config.maxScore).contains(score))
  }

  @Test func customMinScoreIsTheFloor() {
    let config = SleepScoreConfig(minScore: 20)
    let worst = SleepInputs(
      totalDuration: 8 * Self.hour, snoringDuration: 8 * Self.hour,
      snoringEpisodeCount: 400, epicSnoring: 8 * Self.hour)
    #expect(SleepScore.compute(worst, config: config) == 20)
  }
}
