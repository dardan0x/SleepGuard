import Foundation
import ModelsTestSupport
import Testing
@testable import Models

/// `SleepSession` durations, percentages, sleep-talking stats, stage stats,
/// and the cached snoring-duration path.
@MainActor
struct SessionStatsTests {
  private let store: TestStore
  private let start = TestCalendar.date(day: 1, hour: 23)

  init() throws {
    store = try TestStore()
  }

  private func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  // MARK: - Durations

  @Test func unfinishedSessionHasZeroDurationAndPercentages() throws {
    let session = try store.insert(SleepSession(startDate: start), events: [.fixture(at: at(0), duration: 60)])
    #expect(session.totalDuration == 0)
    #expect(session.snoringPercentage == 0)
    #expect(session.sleepTalkingPercentage == 0)
    #expect(session.sleepTalkingEventsPerHour == 0)
  }

  @Test func monitoredDurationSubtractsGaps() throws {
    let session = try store.insert(
      .fixture(start: start, hours: 8),
      gaps: [RecordingGap(startOffset: 0, duration: 600), RecordingGap(startOffset: 3600, duration: 1200)])
    #expect(session.gapsDuration == 1800)
    #expect(session.monitoredDuration == 27000)
  }

  @Test func monitoredDurationNeverGoesNegative() throws {
    let session = try store.insert(
      .fixture(start: start, hours: 1),
      gaps: [RecordingGap(startOffset: 0, duration: 7200)])
    #expect(session.monitoredDuration == 0)
  }

  @Test func snoringPercentageOfTotalDuration() throws {
    let session = try store.insert(.fixture(start: start, hours: 8), events: [.fixture(at: at(0), duration: 2880)])
    #expect(session.snoringDuration == 2880)
    #expect(session.snoringPercentage == 10)
  }

  @Test func cachedSnoringDurationWinsWhenCached() throws {
    let session = try store.insert(.fixture(start: start), events: [.fixture(at: at(0), duration: 2880)])
    session.hasCachedScore = true
    session.cachedSnoringDuration = 99
    #expect(session.snoringDuration == 99)
  }

  // MARK: - Sleep talking + categories

  @Test func sleepTalkingStatsCountOnlySleepTalking() throws {
    let session = try store.insert(.fixture(start: start, hours: 8), events: [
      .fixture(at: at(0), duration: 60, category: .sleepTalking),
      .fixture(at: at(600), duration: 84, category: .sleepTalking),
      .fixture(at: at(1200), duration: 500),
    ])
    #expect(session.sleepTalkingEvents == 2)
    #expect(session.sleepTalkingDuration == 144)
    #expect(session.sleepTalkingPercentage == 0.5) // 144 / 28800
    #expect(session.sleepTalkingEventsPerHour == 0.25)
    #expect(session.duration(for: .sleepTalking) == 144)
    #expect(session.duration(for: .snoring) == 500)
  }

  // MARK: - Stage stats

  @Test func stageStatsNilWithoutSegments() throws {
    let session = try store.insert(.fixture(start: start))
    #expect(session.stageStats == nil)
    session.sleepStageSegments = []
    #expect(session.stageStats == nil)
    session.sleepStageSegments = [SleepStageSegment(stage: .deep, startOffset: 0, duration: 0)]
    #expect(session.stageStats == nil)
  }

  @Test func stageStatsArePercentagesOfSegmentTotal() throws {
    let session = try store.insert(.fixture(start: start))
    session.sleepStageSegments = [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 30),
      SleepStageSegment(stage: .light, startOffset: 30, duration: 40),
      SleepStageSegment(stage: .rem, startOffset: 70, duration: 10),
      SleepStageSegment(stage: .deep, startOffset: 80, duration: 10),
      SleepStageSegment(stage: .awake, startOffset: 90, duration: 10),
    ]
    let stats = try #require(session.stageStats)
    #expect(stats.deepPct == 40)
    #expect(stats.lightPct == 40)
    #expect(stats.remPct == 10)
    #expect(stats.awakePct == 10)
  }

  // MARK: - Save threshold

  @Test func debugMinimumSaveDurationIsTwoMinutes() {
    // Tests build in Debug; Release uses 30 minutes.
    #expect(SleepSession.minimumSaveDuration == 120)
  }
}
