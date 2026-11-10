import Foundation
import Models
import ModelsTestSupport
import Testing
@testable import Statistics

/// The session → dashboard mapping, on a fixed clock and a fixed-zone calendar.
struct DashboardStateTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
    return calendar
  }()

  /// 2026-11-10 08:00 local.
  private var now: Date {
    date(day: 10, hour: 8)
  }

  private func date(day: Int, hour: Int, minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
  }

  private func session(day: Int, hour: Int, minute: Int = 0, hours: Double = 7, score: Int = 80) -> SleepSession {
    let session = SleepSession.fixture(start: date(day: day, hour: hour, minute: minute), hours: hours)
    session.hasCachedScore = true
    session.cachedSleepScore = score
    return session
  }

  private func make(_ sessions: [SleepSession]) -> DashboardState? {
    DashboardState.make(from: sessions, now: now, calendar: calendar)
  }

  @Test func noSessionsIsEmpty() {
    #expect(make([]) == nil)
  }

  @Test func latestSessionWinsRegardlessOfInputOrder() throws {
    let older = session(day: 7, hour: 23)
    let latest = session(day: 9, hour: 23)
    let state = try #require(make([older, latest]))
    #expect(state.session === latest)
    #expect(state.recentSessions.map(\.id) == [latest.id, older.id])
  }

  @Test func recentSessionsAreCappedAtSeven() throws {
    let sessions = (1...9).map { session(day: $0, hour: 23) }
    let state = try #require(make(sessions))
    #expect(state.recentSessions.count == 7)
    #expect(state.recentSessions.first?.startDate == date(day: 9, hour: 23))
  }

  @Test func sessionStartedYesterdayEveningIsLastNight() throws {
    let state = try #require(make([session(day: 9, hour: 23, minute: 30)]))
    #expect(state.isLastNight)
  }

  @Test func olderSessionIsLastTime() throws {
    let state = try #require(make([session(day: 7, hour: 23)]))
    #expect(!state.isLastNight)
  }

  /// Pins current behavior: "last night" is judged by start date, so a bedtime
  /// after midnight (today 00:30) reads as "last time" the same morning.
  @Test func sessionStartedAfterMidnightIsNotLastNight() throws {
    let state = try #require(make([session(day: 10, hour: 0, minute: 30)]))
    #expect(!state.isLastNight)
  }

  /// A session crossing midnight belongs to the day it started: it shares a day
  /// with an earlier nap that day, not with a session started after midnight.
  @Test func sessionCrossingMidnightGroupsByStartDay() throws {
    let nap = session(day: 9, hour: 15, hours: 1, score: 60)
    let night = session(day: 9, hour: 23, hours: 8, score: 90)
    let state = try #require(make([nap, night]))
    #expect(state.session === night)
    #expect(state.daySessionCount == 2)
    #expect(state.dayScore == 75)
  }

  @Test func dayScoreIgnoresOtherDays() throws {
    let state = try #require(make([session(day: 8, hour: 23, score: 40), session(day: 9, hour: 23, score: 90)]))
    #expect(state.daySessionCount == 1)
    #expect(state.dayScore == 90)
  }

  /// A force-saved session (low battery, crash recovery) may not have a cached
  /// score yet. The dashboard computes it from events instead of showing 0.
  @Test func uncachedSessionUsesComputedScore() throws {
    let store = try TestStore()
    let start = date(day: 9, hour: 23)
    let forceSaved = try store.insert(
      SleepSession.fixture(start: start),
      events: [SnoreEvent.fixture(at: start.addingTimeInterval(600), duration: 1800, intensity: .loud)])
    #expect(!forceSaved.hasCachedScore)

    let state = try #require(make([forceSaved]))
    #expect(state.dayScore == forceSaved.sleepScore(using: .default))
    #expect(state.dayScore > 0)
  }

  /// A cache written by an older formula still shows its cached value until the
  /// launch pass (`refreshStaleCachedScores`) rewrites it. The mapping never
  /// recomputes on its own.
  @Test func staleCachedScoreIsShownAsCached() throws {
    let stale = session(day: 9, hour: 23, score: 42)
    stale.cachedScoreVersion = "0-stale"
    let state = try #require(make([stale]))
    #expect(state.dayScore == 42)
  }
}
