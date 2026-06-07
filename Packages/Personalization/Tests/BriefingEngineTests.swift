import Foundation
import Testing
import Models
@testable import Personalization

struct BriefingEngineTests {

  // MARK: - Helpers

  private var calendar: Calendar { Calendar.current }

  private func makeSession(
    startDate: Date,
    endDate: Date? = nil,
    durationHours: Double = 1,
    sleepScore: Int = 100,
    snoringDuration: TimeInterval = 0
  ) -> BriefingSession {
    BriefingSession(
      startDate: startDate,
      endDate: endDate ?? startDate.addingTimeInterval(durationHours * 3600),
      sleepScore: sleepScore,
      snoringDuration: snoringDuration,
      totalDuration: durationHours * 3600
    )
  }

  private func date(hour: Int, dayOffset: Int = 0) -> Date {
    var comps = DateComponents()
    comps.year = 2026
    comps.month = 6
    comps.day = 1 + dayOffset
    comps.hour = hour
    comps.minute = 0
    return calendar.date(from: comps)!
  }

  // MARK: - No Data

  @Test func noData_whenNoSessions() {
    let now = date(hour: 8)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.scoreContext == .noData)
    #expect(briefing.stats.isEmpty)
    #expect(briefing.survey == nil)
    #expect(briefing.insight == nil)
  }

  // MARK: - First Night

  @Test func firstNight_whenSingleSession() {
    let now = date(hour: 8)
    let session = makeSession(startDate: date(hour: 23, dayOffset: -1))
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.scoreContext == .firstNight)
    #expect(briefing.insight == nil)
    #expect(briefing.survey == nil)
    #expect(briefing.stats.count == 3)
  }

  // MARK: - Returning After Gap

  @Test func returningAfterGap_whenLatestSessionIs5DaysAgo() {
    let now = date(hour: 8)
    let oldSession = makeSession(startDate: date(hour: 23, dayOffset: -6))
    let recentSession = makeSession(startDate: date(hour: 23, dayOffset: -5))
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [recentSession, oldSession],
      lifestyleLogs: [],
      now: now
    )

    if case .returningAfterGap(let days) = briefing.scoreContext {
      #expect(days == 5)
    } else {
      Issue.record("Expected .returningAfterGap, got \(briefing.scoreContext)")
    }
  }

  // MARK: - Score Trend: Improving / Declining / Steady

  @Test func improving_whenLatestScoreIsMuchHigher() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 60)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 85)

    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.scoreContext == .improving)
  }

  @Test func declining_whenLatestScoreIsMuchLower() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 80)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 55)

    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.scoreContext == .declining)
  }

  @Test func steady_whenScoresAreClose() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 74)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 76)

    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.scoreContext == .steady)
  }

  // MARK: - Greeting by Time

  @Test func greetingMorning() {
    let now = date(hour: 8)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.greeting.contains("morning"))
  }

  @Test func greetingAfternoon() {
    let now = date(hour: 14)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.greeting.contains("afternoon"))
  }

  @Test func greetingEvening() {
    let now = date(hour: 20)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.greeting.contains("evening"))
  }

  @Test func greetingNight() {
    let now = date(hour: 2)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.greeting.contains("night"))
  }

  @Test func greetingWithName() {
    let now = date(hour: 8)
    let profile = BriefingProfile(firstName: "Alex")
    let briefing = BriefingEngine.generate(
      profile: profile,
      recentSessions: [],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.greeting.contains("Alex"))
  }

  // MARK: - Headline

  @Test func headlineQuietNight() {
    let now = date(hour: 8)
    let session = makeSession(startDate: date(hour: 23, dayOffset: -1), durationHours: 8)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.headline.contains("quiet"))
  }

  @Test func headlineNormalNight() {
    let now = date(hour: 8)
    let session = makeSession(
      startDate: date(hour: 23, dayOffset: -1),
      durationHours: 8,
      snoringDuration: 1800
    )
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )
    #expect(!briefing.headline.contains("quiet"))
  }

  // MARK: - Stats

  @Test func statsIncludeSleepSnoringScore() {
    let now = date(hour: 8)
    let session = makeSession(
      startDate: date(hour: 23, dayOffset: -1),
      durationHours: 8,
      snoringDuration: 1800
    )
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.stats.count == 3)
    #expect(briefing.stats[0].label != nil)
    #expect(briefing.stats[1].label != nil)
    #expect(briefing.stats[2].label != nil)
  }

  // MARK: - Insight

  @Test func noInsight_whenSingleSession() {
    let now = date(hour: 8)
    let session = makeSession(startDate: date(hour: 23, dayOffset: -1), durationHours: 8)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.insight == nil)
  }

  @Test func insightImproving() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 60)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 85)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.insight != nil)
  }

  @Test func insightIncludesGoalShortfall() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), durationHours: 5)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), durationHours: 5)
    let profile = BriefingProfile(targetSleepHours: 8)

    let briefing = BriefingEngine.generate(
      profile: profile,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.insight != nil)
  }

  // MARK: - Survey Gate

  @Test func noSurvey_whenLessThan2Sessions() {
    let now = date(hour: 8)
    let session = makeSession(startDate: date(hour: 23, dayOffset: -1), durationHours: 8)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [session],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.survey == nil)
  }

  @Test func noSurvey_whenScoreSwingIsSmall() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 75)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 78)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )
    #expect(briefing.survey == nil)
  }

  @Test func noSurvey_whenLogAlreadyExists() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 60)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 85)
    let log = LifestyleLog(
      date: s2.startDate,
      hadCaffeineLate: false,
      hadAlcohol: false,
      exercised: false,
      stressfulDay: false,
      lateMeal: false,
      screenBeforeBed: false
    )

    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [log],
      now: now
    )
    #expect(briefing.survey == nil)
  }

  @Test func surveyPositive_whenScoreImprovedBy15Plus() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 60)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 85)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.survey != nil)
    #expect(briefing.survey?.isPositiveSwing == true)
    #expect(briefing.survey?.chips.count == 5)
  }

  @Test func surveyNegative_whenScoreDeclinedBy15Plus() {
    let now = date(hour: 8)
    let s1 = makeSession(startDate: date(hour: 23, dayOffset: -2), sleepScore: 85)
    let s2 = makeSession(startDate: date(hour: 23, dayOffset: -1), sleepScore: 55)
    let briefing = BriefingEngine.generate(
      profile: nil,
      recentSessions: [s2, s1],
      lifestyleLogs: [],
      now: now
    )

    #expect(briefing.survey != nil)
    #expect(briefing.survey?.isPositiveSwing == false)
    #expect(briefing.survey?.chips.count == 5)
  }

  // MARK: - QuoteBank

  @Test func quoteForImproving() {
    let q = QuoteBank.quote(for: .improving)
    #expect(!q.isEmpty)
  }

  @Test func quoteForDeclining() {
    let q = QuoteBank.quote(for: .declining)
    #expect(!q.isEmpty)
  }

  @Test func quoteForSteady() {
    let q = QuoteBank.quote(for: .steady)
    #expect(!q.isEmpty)
  }

  @Test func quoteForFirstNight() {
    let q = QuoteBank.quote(for: .firstNight)
    #expect(!q.isEmpty)
  }

  @Test func quoteForNoData() {
    let q = QuoteBank.quote(for: .noData)
    #expect(!q.isEmpty)
  }

  @Test func quoteForReturningAfterGap() {
    let q = QuoteBank.quote(for: .returningAfterGap(days: 5))
    #expect(!q.isEmpty)
  }
}
