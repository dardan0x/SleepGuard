import Foundation
import ModelsTestSupport
import SleepCore
import Testing
@testable import Models

/// `SleepSession.sleepScore(using:)` with the default config. Each test isolates
/// one penalty; the comment shows the arithmetic so a formula change points at
/// the exact number that moved. Quiet-intensity events carry no intensity penalty.
@MainActor
struct SleepScoreTests {
  private let store: TestStore
  private let start = TestCalendar.date(day: 1, hour: 23)

  init() throws {
    store = try TestStore()
  }

  private func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  private func night(
    hours: Double = 8,
    events: [SnoreEvent] = [],
    gaps: [RecordingGap] = []) throws -> SleepSession
  {
    try store.insert(.fixture(start: start, hours: hours), events: events, gaps: gaps)
  }

  private func score(_ session: SleepSession) -> Int {
    session.sleepScore(using: .default)
  }

  // MARK: - Baseline

  @Test func unfinishedSessionScoresMax() throws {
    let session = try store.insert(SleepSession(startDate: start))
    #expect(score(session) == 100)
  }

  @Test func cleanEightHourNightScoresMax() throws {
    #expect(try score(night()) == 100)
  }

  @Test func customConfigMaxScoreIsUsed() throws {
    #expect(try night().sleepScore(using: SleepScoreConfig(maxScore: 50)) == 50)
  }

  // MARK: - Duration

  @Test func shortNightIsPenalized() throws {
    // (6 h threshold − 4 h) × 2 = 4
    #expect(try score(night(hours: 4)) == 96)
  }

  @Test func sessionUnderThreeHoursHasNoShortSleepPenalty() throws {
    #expect(try score(night(hours: 2)) == 100)
  }

  @Test func longNightIsPenalized() throws {
    // (11 h − 9 h threshold) × 1 = 2
    #expect(try score(night(hours: 11)) == 98)
  }

  @Test func longNightPenaltyIsCapped() throws {
    // (15 h − 9 h) × 1 = 6 → cap 5
    #expect(try score(night(hours: 15)) == 95)
  }

  // MARK: - Snoring duration + intensity

  @Test func tenPercentLightSnoring() throws {
    // snoring 2880 / 28800 = 10 % × 0.85 = 8; events 1/8 h × 2.5 = 0; light ratio 1 × 10 = 10
    let session = try night(events: [.fixture(at: at(3600), duration: 2880, intensity: .light)])
    #expect(score(session) == 82)
  }

  @Test func intensityPenaltyIsCapped() throws {
    // snoring 8; epic ratio 1 × 40 = 40 → cap 30
    let session = try night(events: [.fixture(at: at(3600), duration: 2880, intensity: .epic)])
    #expect(score(session) == 62)
  }

  @Test func scoreNeverDropsBelowMin() throws {
    // snoring 100 % × 0.85 = 85 → cap 75; epic → cap 30; 100 − 105 → clamp 0
    let session = try night(events: [.fixture(at: start, duration: 28800, intensity: .epic)])
    #expect(score(session) == 0)
  }

  @Test func intensityRatiosUseBurstSumNotEventSpan() throws {
    // Light event spans 600 s but only 60 s of bursts; epic event 60 s, no bursts.
    // Detected = 120 s → light 0.5 × 10 + epic 0.5 × 40 = 25.
    // (By span it would be 600/660 light + 60/660 epic = 12.)
    // snoring (600 + 60) / 28800 = 2.3 % × 0.85 = 1; 2 episodes / 8 h × 2.5 = 0
    let light = SnoreEvent.fixture(
      at: at(3600), duration: 600, intensity: .light,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 30), SnoreBurst(startOffset: 300, endOffset: 330)])
    let epic = SnoreEvent.fixture(at: at(4 * 3600), duration: 60, intensity: .epic)
    #expect(try score(night(events: [light, epic])) == 74)
  }

  // MARK: - Events per hour

  @Test func manyEpisodesArePenalized() throws {
    // 20 quiet 10 s events, 20 min apart → 20 episodes / 8 h × 2.5 = 6; snoring 200 s → 0
    let events = (0..<20).map { SnoreEvent.fixture(at: at(Double($0) * 1200), duration: 10, intensity: .quiet) }
    #expect(try score(night(events: events)) == 94)
  }

  @Test func microEpisodesDoNotCountAsEvents() throws {
    // Same, but 2 s each: episodes under 3 s aren't displayable → no events penalty
    let events = (0..<20).map { SnoreEvent.fixture(at: at(Double($0) * 1200), duration: 2, intensity: .quiet) }
    #expect(try score(night(events: events)) == 100)
  }

  @Test func eventsWithinFiveMinutesMergeIntoOneEpisode() throws {
    // 20 quiet 10 s events, 2 min apart → 1 episode → 1/8 h × 2.5 = 0
    let events = (0..<20).map { SnoreEvent.fixture(at: at(Double($0) * 120), duration: 10, intensity: .quiet) }
    #expect(try score(night(events: events)) == 100)
  }

  // MARK: - Recording gaps

  @Test func gapWhereSnoringResumedCountsAsSnoring() throws {
    // Uncovered gap: snoring (60 + 2880) / 28800 = 10.2 % × 0.85 = 8
    let session = try night(
      events: [.fixture(at: start, duration: 60, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 7200, duration: 2880)])
    #expect(score(session) == 92)
  }

  @Test func gapWhereSnoringDidNotResumeIsIgnored() throws {
    let session = try night(
      events: [.fixture(at: start, duration: 60, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 7200, duration: 2880, snoringResumed: false)])
    #expect(score(session) == 100)
  }

  @Test func gapInsideAnEventIsNotDoubleCounted() throws {
    // Event 0–3000 s covers the gap 600–1800 s → snoring stays 3000 s:
    // 10.4 % × 0.85 = 8 (would be 4200 s → 12 if the gap were added again)
    let session = try night(
      events: [.fixture(at: start, duration: 3000, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 600, duration: 1200)])
    #expect(score(session) == 92)
  }

  // MARK: - Sleep talking

  @Test func sleepTalkingIsPenalized() throws {
    // 40 × 60 s: 8.33 % × 0.35 = 2.9 + 5/h × 0.8 = 4 → 6. Not counted as snoring episodes.
    let events = (0..<40).map {
      SnoreEvent.fixture(at: at(Double($0) * 600), duration: 60, intensity: .quiet, category: .sleepTalking)
    }
    #expect(try score(night(events: events)) == 94)
  }

  // MARK: - Sleep stages

  @Test func missingDeepAndRemIsPenalizedAndCapped() throws {
    // deep (15 − 0) × 0.6 = 9 + REM (18 − 0) × 0.4 = 7.2 → 16 → cap 15
    let session = try night()
    session.sleepStageSegments = [SleepStageSegment(stage: .light, startOffset: 0, duration: 28800)]
    #expect(score(session) == 85)
  }

  @Test func healthyStagesHaveNoPenalty() throws {
    // deep 20 %, REM 25 %, awake 5 %, light 50 %
    let session = try night()
    session.sleepStageSegments = [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 20),
      SleepStageSegment(stage: .rem, startOffset: 20, duration: 25),
      SleepStageSegment(stage: .awake, startOffset: 45, duration: 5),
      SleepStageSegment(stage: .light, startOffset: 50, duration: 50),
    ]
    #expect(score(session) == 100)
  }

  // MARK: - Cache

  @Test func cachedScoreIsReturnedWithoutRecomputing() throws {
    let session = try night(events: [.fixture(at: at(3600), duration: 2880, intensity: .light)])
    // Production writes both cached values together. Note: `sleepScore(using:)`
    // recomputes the score but reads `snoringDuration`, which returns
    // `cachedSnoringDuration` once `hasCachedScore` is set.
    session.hasCachedScore = true
    session.cachedSleepScore = 42
    session.cachedSnoringDuration = 2880
    #expect(session.sleepScore == 42)
    #expect(score(session) == 82)
  }

  @Test func uncachedScoreFallsBackToDefaultConfig() throws {
    let session = try night(events: [.fixture(at: at(3600), duration: 2880, intensity: .light)])
    #expect(session.sleepScore == 82)
  }
}
