import Foundation
import Models
import Testing
@testable import Recordings

/// History list grouping: months newest first, nights newest first, sessions
/// newest first. The grouper uses `Calendar.current`, so dates are built with it
/// at midday to stay clear of time-zone day boundaries.
struct SessionGrouperTests {
  private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }

  private func session(_ start: Date, score: Int = 80, hours: Double = 8) -> SleepSession {
    let session = SleepSession.fixture(start: start, hours: hours)
    session.hasCachedScore = true
    session.cachedSleepScore = score
    return session
  }

  @Test func emptyInputProducesNoSections() {
    #expect(SessionGrouper.groupSessions([]).isEmpty)
  }

  @Test func monthsAreNewestFirstAcrossAYearBoundary() {
    let sections = SessionGrouper.groupSessions([
      session(date(2025, 12, 30)),
      session(date(2026, 2, 3)),
      session(date(2026, 1, 15)),
    ])
    let months = sections.map { Calendar.current.dateComponents([.year, .month], from: $0.groups[0].date) }
    #expect(months.map(\.year) == [2026, 2026, 2025])
    #expect(months.map(\.month) == [2, 1, 12])
  }

  @Test func nightsAndSessionsAreNewestFirst() throws {
    let morning = session(date(2026, 3, 4, hour: 9))
    let evening = session(date(2026, 3, 4, hour: 21))
    let otherDay = session(date(2026, 3, 1))
    let sections = SessionGrouper.groupSessions([morning, otherDay, evening])

    let groups = try #require(sections.first?.groups)
    #expect(sections.count == 1)
    #expect(groups.count == 2)
    #expect(groups[0].sessions.map(\.id) == [evening.id, morning.id])
    #expect(groups[0].latestSession.id == evening.id)
    #expect(groups[1].sessions.map(\.id) == [otherDay.id])
  }

  @Test func groupIDIsTheISODayAndTitleIsUppercased() throws {
    let sections = SessionGrouper.groupSessions([session(date(2026, 3, 4))])
    let section = try #require(sections.first)
    #expect(section.groups[0].id == "2026-03-04")
    #expect(section.title == section.title.uppercased())
    #expect(section.id == section.title)
  }

  @Test func nightGroupTotals() {
    let group = NightGroup(id: "x", date: date(2026, 3, 4), sessions: [
      session(date(2026, 3, 4, hour: 1), score: 80, hours: 2),
      session(date(2026, 3, 4, hour: 4), score: 71, hours: 3),
    ])
    #expect(group.averageScore == 75) // (80 + 71) / 2, integer division
    #expect(group.totalDuration == 5 * 3600)
    #expect(group.recordingCount == 2)
    #expect(group.totalEvents == 0)
  }
}
