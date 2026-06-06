import Foundation
import Models
import DesignSystem

public enum BriefingEngine {
  public static func generate(
    profile: UserProfile?,
    recentSessions: [SleepSession],
    lifestyleLogs: [LifestyleLog],
    now: Date
  ) -> Briefing {
    let calendar = Calendar.current
    let sortedSessions = recentSessions.sorted { $0.startDate > $1.startDate }

    // Edge cases
    guard let latestSession = sortedSessions.first else {
      return Briefing(
        greeting: greeting(for: now, name: profile?.firstName),
        headline: Strings.briefingHeadlineWelcome,
        stats: [],
        insight: nil,
        nudge: QuoteBank.quote(for: .noData),
        survey: nil,
        scoreContext: .noData
      )
    }

    let scoreContext = determineScoreContext(
      sessions: sortedSessions,
      now: now,
      calendar: calendar
    )

    let headline = buildHeadline(for: latestSession)
    let stats = buildStats(for: latestSession)
    let insight = buildInsight(
      sessions: sortedSessions,
      profile: profile,
      calendar: calendar
    )
    let survey = buildSurvey(
      latestSession: latestSession,
      sessions: sortedSessions,
      lifestyleLogs: lifestyleLogs,
      calendar: calendar
    )

    return Briefing(
      greeting: greeting(for: now, name: profile?.firstName),
      headline: headline,
      stats: stats,
      insight: insight,
      nudge: QuoteBank.quote(for: scoreContext),
      survey: survey,
      scoreContext: scoreContext
    )
  }

  // MARK: - Greeting

  private static func greeting(for date: Date, name: String?) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    let hasName = name != nil && !name!.isEmpty

    switch hour {
    case 5..<12:
      return hasName
        ? String(format: Strings.briefingGreetingMorning, name!)
        : Strings.briefingGreetingMorningNoName
    case 12..<18:
      return hasName
        ? String(format: Strings.briefingGreetingAfternoon, name!)
        : Strings.briefingGreetingAfternoonNoName
    case 18..<23:
      return hasName
        ? String(format: Strings.briefingGreetingEvening, name!)
        : Strings.briefingGreetingEveningNoName
    default:
      return hasName
        ? String(format: Strings.briefingGreetingNight, name!)
        : Strings.briefingGreetingNightNoName
    }
  }

  // MARK: - Score Context

  private static func determineScoreContext(
    sessions: [SleepSession],
    now: Date,
    calendar: Calendar
  ) -> ScoreTrend {
    guard sessions.count >= 1 else { return .noData }
    guard sessions.count > 1 else { return .firstNight }

    let latest = sessions[0]
    let daysSinceLatest = calendar.dateComponents(
      [.day],
      from: calendar.startOfDay(for: latest.startDate),
      to: calendar.startOfDay(for: now)
    ).day ?? 0

    if daysSinceLatest > 3 {
      return .returningAfterGap(days: daysSinceLatest)
    }

    let latestScore = latest.sleepScore
    let previousSessions = sessions.dropFirst()
    let recentScores = previousSessions.prefix(6).map(\.sleepScore)
    guard !recentScores.isEmpty else { return .firstNight }

    let avg = recentScores.reduce(0, +) / recentScores.count
    let diff = latestScore - avg

    if diff > 5 { return .improving }
    if diff < -5 { return .declining }
    return .steady
  }

  // MARK: - Headline

  private static func buildHeadline(for session: SleepSession) -> String {
    let duration = session.totalDuration
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let durationText = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

    let snoringMinutes = Int(session.snoringDuration / 60)
    let score = session.sleepScore

    if snoringMinutes == 0 {
      return String(format: Strings.briefingHeadlineQuiet, durationText)
    }

    return String(format: Strings.briefingHeadlineNormal, durationText, snoringMinutes, score)
  }

  // MARK: - Stats

  private static func buildStats(for session: SleepSession) -> [BriefingStat] {
    let duration = session.totalDuration
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let durationText = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

    return [
      BriefingStat(label: Strings.briefingStatSleep, value: durationText),
      BriefingStat(label: Strings.briefingStatSnoring, value: "\(Int(session.snoringDuration / 60))m"),
      BriefingStat(label: Strings.briefingStatScore, value: "\(session.sleepScore)"),
    ]
  }

  // MARK: - Insight

  private static func buildInsight(
    sessions: [SleepSession],
    profile: UserProfile?,
    calendar: Calendar
  ) -> String? {
    guard sessions.count >= 2 else { return nil }

    let latest = sessions[0]
    let latestScore = latest.sleepScore
    let recentScores = sessions.dropFirst().prefix(6).map(\.sleepScore)
    let avg = recentScores.reduce(0, +) / max(recentScores.count, 1)
    let diff = latestScore - avg

    var parts: [String] = []

    if diff > 5 {
      parts.append(String(format: Strings.briefingInsightImproving, latestScore, avg))
    } else if diff < -5 {
      parts.append(String(format: Strings.briefingInsightDeclining, latestScore, avg))
    } else {
      parts.append(String(format: Strings.briefingInsightSteady, avg))
    }

    if let target = profile?.targetSleepHours, target > 0 {
      let avgDuration = recentScores.count >= 3
        ? sessions.prefix(3).map(\.totalDuration).reduce(0, +) / Double(min(sessions.count, 3))
        : latest.totalDuration
      let avgHours = Int(avgDuration / 3600)
      let avgMinutes = (Int(avgDuration) % 3600) / 60
      let shortfall = target - (avgDuration / 3600)
      if shortfall > 0.25 {
        let shortMinutes = Int(shortfall * 60)
        parts.append(
          String(format: Strings.briefingInsightGoalShortfall,
                 avgHours, avgMinutes, shortMinutes, Int(target))
        )
      }
    }

    return parts.joined(separator: " ")
  }

  // MARK: - Survey

  private static func buildSurvey(
    latestSession: SleepSession,
    sessions: [SleepSession],
    lifestyleLogs: [LifestyleLog],
    calendar: Calendar
  ) -> SurveyPrompt? {
    guard sessions.count >= 2 else { return nil }

    let latestScore = latestSession.sleepScore
    let recentScores = sessions.dropFirst().prefix(6).map(\.sleepScore)
    let avg = recentScores.reduce(0, +) / max(recentScores.count, 1)
    let diff = abs(latestScore - avg)

    guard diff >= 15 else { return nil }

    // Check if a log already exists for this night
    let nightStart = calendar.startOfDay(for: latestSession.startDate)
    let hasLog = lifestyleLogs.contains { log in
      calendar.isDate(calendar.startOfDay(for: log.date), inSameDayAs: nightStart)
    }
    guard !hasLog else { return nil }

    let isPositive = latestScore > avg
    if isPositive {
      return SurveyPrompt(
        title: Strings.briefingSurveyPositiveTitle,
        chips: [
          Strings.briefingSurveyChipExercised,
          Strings.briefingSurveyChipLessCaffeine,
          Strings.briefingSurveyChipNoAlcohol,
          Strings.briefingSurveyChipSleptEarlier,
          Strings.briefingSurveyChipLessStress,
        ],
        isPositiveSwing: true
      )
    } else {
      return SurveyPrompt(
        title: Strings.briefingSurveyNegativeTitle,
        chips: [
          Strings.briefingSurveyChipLateCaffeine,
          Strings.briefingSurveyChipAlcohol,
          Strings.briefingSurveyChipStressfulDay,
          Strings.briefingSurveyChipLateMeal,
          Strings.briefingSurveyChipScreensInBed,
        ],
        isPositiveSwing: false
      )
    }
  }
}
