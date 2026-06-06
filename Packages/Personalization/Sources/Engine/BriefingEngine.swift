import Foundation
import Models

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
        headline: "Record your first night and I'll start learning your sleep.",
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
    let timeGreeting: String
    switch hour {
    case 5..<12:
      timeGreeting = "Good morning"
    case 12..<18:
      timeGreeting = "Good afternoon"
    case 18..<23:
      timeGreeting = "Good evening"
    default:
      timeGreeting = "Still up"
    }
    guard let name, !name.isEmpty else { return "\(timeGreeting)." }
    return "\(timeGreeting), \(name)."
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
      return "Last night you slept \(durationText). A quiet night — nice work."
    }

    return "Last night you slept \(durationText) with \(snoringMinutes) min of snoring. Score: \(score)."
  }

  // MARK: - Stats

  private static func buildStats(for session: SleepSession) -> [BriefingStat] {
    let duration = session.totalDuration
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let durationText = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

    return [
      BriefingStat(label: "Sleep", value: durationText),
      BriefingStat(label: "Snoring", value: "\(Int(session.snoringDuration / 60))m"),
      BriefingStat(label: "Score", value: "\(session.sleepScore)"),
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
      parts.append("Your score climbed to \(latestScore), up from a \(avg) recent average.")
    } else if diff < -5 {
      parts.append("\(latestScore) tonight — below your \(avg) recent average.")
    } else {
      parts.append("Holding steady around \(avg) recently. Consistency is its own win.")
    }

    if let target = profile?.targetSleepHours, target > 0 {
      let avgDuration = recentScores.count >= 3
        ? sessions.prefix(3).map(\.totalDuration).reduce(0, +) / Double(min(sessions.count, 3))
        : latest.totalDuration
      let avgHours = avgDuration / 3600
      let shortfall = target - avgHours
      if shortfall > 0.25 {
        let shortMinutes = Int(shortfall * 60)
        parts.append("You're averaging about \(Int(avgHours))h \(shortMinutes)m — about \(shortMinutes) min short of your \(Int(target))h goal.")
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
        title: "Nice jump tonight. What did you do differently?",
        chips: ["Exercised", "Less caffeine", "No alcohol", "Slept earlier", "Less stress"],
        isPositiveSwing: true
      )
    } else {
      return SurveyPrompt(
        title: "Tougher night. Anything unusual yesterday?",
        chips: ["Late caffeine", "Alcohol", "Stressful day", "Late meal", "Screens in bed"],
        isPositiveSwing: false
      )
    }
  }
}
