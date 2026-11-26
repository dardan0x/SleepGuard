import Foundation
import Models
import ModelsTestSupport
import SleepCore
import SleepStore
import Testing

/// Stored sessions → the shared `NightSummary` the statistics rules read.
@MainActor
struct NightSummaryMappingTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  @Test func fullSummaryReadsEvents() throws {
    let store = try TestStore()
    let session = try store.insert(
      NightRecord.fixture(start: start, hours: 7),
      events: [
        NightEventRecord.fixture(at: start.addingTimeInterval(600), duration: 120, intensity: .light),
        NightEventRecord.fixture(at: start.addingTimeInterval(3600), duration: 90, intensity: .loud),
      ])
    session.refreshSummary(using: .default)
    let summary = session.summary
    #expect(summary.id == session.id)
    #expect(summary.start == start)
    #expect(summary.duration == 7 * 3600)
    #expect(summary.score == session.score)
    #expect(summary.snoringDuration == session.snoringDuration)
    #expect(summary.eventCount == session.eventCount)
    #expect(summary.loudestIntensity == .loud)
  }

  @Test func theSummaryIsTheStoredFields() {
    let session = NightRecord.fixture(start: start, hours: 7)
    session.scoreVersion = "cached"
    session.score = 64
    session.snoringDuration = 900
    let summary = session.summary
    #expect(summary.score == 64)
    #expect(summary.snoringDuration == 900)
    #expect(summary.duration == 7 * 3600)
    #expect(summary.eventCount == 0)
    #expect(summary.loudestIntensity == nil)
  }

  @Test func nightWithoutEventsHasNoLoudestIntensity() throws {
    let store = try TestStore()
    let session = try store.insert(NightRecord.fixture(start: start), events: [])
    #expect(session.summary.loudestIntensity == nil)
  }
}
