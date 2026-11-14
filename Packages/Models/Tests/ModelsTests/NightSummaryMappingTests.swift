import Foundation
import Models
import ModelsTestSupport
import SleepCore
import Testing

/// Stored sessions → the shared `NightSummary` the statistics rules read.
@MainActor
struct NightSummaryMappingTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  @Test func fullSummaryReadsEvents() throws {
    let store = try TestStore()
    let session = try store.insert(
      SleepSession.fixture(start: start, hours: 7),
      events: [
        SnoreEvent.fixture(at: start.addingTimeInterval(600), duration: 120, intensity: .light),
        SnoreEvent.fixture(at: start.addingTimeInterval(3600), duration: 90, intensity: .loud),
      ])
    let summary = session.nightSummary
    #expect(summary.id == session.id)
    #expect(summary.start == start)
    #expect(summary.duration == 7 * 3600)
    #expect(summary.score == session.sleepScore)
    #expect(summary.snoringDuration == session.snoringDuration)
    #expect(summary.eventCount == session.eventsCount)
    #expect(summary.loudestIntensity == .loud)
  }

  @Test func summaryWithoutEventsUsesTheCachedFields() {
    let session = SleepSession.fixture(start: start, hours: 7)
    session.hasCachedScore = true
    session.cachedSleepScore = 64
    session.cachedSnoringDuration = 900
    let summary = session.summaryWithoutEvents
    #expect(summary.score == 64)
    #expect(summary.snoringDuration == 900)
    #expect(summary.duration == 7 * 3600)
    #expect(summary.eventCount == 0)
    #expect(summary.loudestIntensity == nil)
  }

  @Test func nightWithoutEventsHasNoLoudestIntensity() throws {
    let store = try TestStore()
    let session = try store.insert(SleepSession.fixture(start: start), events: [])
    #expect(session.nightSummary.loudestIntensity == nil)
  }
}
