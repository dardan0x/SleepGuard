import Foundation
import Models
import DesignSystem

/// Lightweight value type representing a session for briefing generation.
/// Extracted from `SleepSession` so the engine never touches `@Model` objects.
public struct BriefingSession: Sendable {
  public let startDate: Date
  public let endDate: Date?
  public let sleepScore: Int
  public let snoringDuration: TimeInterval
  public let totalDuration: TimeInterval

  public init(
    startDate: Date,
    endDate: Date? = nil,
    sleepScore: Int,
    snoringDuration: TimeInterval,
    totalDuration: TimeInterval
  ) {
    self.startDate = startDate
    self.endDate = endDate
    self.sleepScore = sleepScore
    self.snoringDuration = snoringDuration
    self.totalDuration = totalDuration
  }
}

/// Lightweight value type representing a profile for briefing generation.
public struct BriefingProfile: Sendable {
  public let firstName: String?
  public let targetSleepHours: Double?
  public let completionPercentage: Double

  public init(
    firstName: String? = nil,
    targetSleepHours: Double? = nil,
    completionPercentage: Double = 0
  ) {
    self.firstName = firstName
    self.targetSleepHours = targetSleepHours
    self.completionPercentage = completionPercentage
  }
}

public enum BriefingEngine {

  private enum ContentMode {
    case lastNightRecap
    case weeklySnoring
    case weeklyScore
    case weeklyDuration
    case combinedScoreSnoring
    case combinedDurationScore
  }

  public static func generate(
    profile: BriefingProfile?,
    recentSessions: [BriefingSession],
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
        scoreContext: .noData,
        profileNudge: profileNudge(for: profile)
      )
    }

    let scoreContext = determineScoreContext(
      sessions: sortedSessions,
      now: now,
      calendar: calendar
    )

    let mode = selectMode(sessions: sortedSessions, now: now, calendar: calendar)
    let (headline, stats, insight) = buildContent(
      mode: mode,
      latestSession: latestSession,
      sessions: sortedSessions,
      profile: profile
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
      scoreContext: scoreContext,
      profileNudge: profileNudge(for: profile)
    )
  }

  private static func selectMode(
    sessions: [BriefingSession],
    now: Date,
    calendar: Calendar
  ) -> ContentMode {
    guard sessions.count >= 2 else { return .lastNightRecap }

    let availableModes: [ContentMode] = [
      .lastNightRecap,
      .weeklySnoring,
      .weeklyScore,
      .weeklyDuration,
      .combinedScoreSnoring,
      .combinedDurationScore,
    ]
    return availableModes.randomElement() ?? .lastNightRecap
  }

  private static func profileNudge(for profile: BriefingProfile?) -> String? {
    guard let profile else { return nil }
    guard profile.completionPercentage < 0.5 else { return nil }
    return Strings.briefingProfileNudge
  }

  private static func buildContent(
    mode: ContentMode,
    latestSession: BriefingSession,
    sessions: [BriefingSession],
    profile: BriefingProfile?
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    switch mode {
    case .lastNightRecap:
      return (
        buildHeadline(for: latestSession),
        buildStats(for: latestSession),
        buildInsight(sessions: sessions, profile: profile)
      )
    case .weeklySnoring:
      return buildWeeklySnoringContent(latest: latestSession, sessions: sessions)
    case .weeklyScore:
      return buildWeeklyScoreContent(latest: latestSession, sessions: sessions)
    case .weeklyDuration:
      return buildWeeklyDurationContent(latest: latestSession, sessions: sessions)
    case .combinedScoreSnoring:
      return buildCombinedScoreSnoringContent(latest: latestSession, sessions: sessions)
    case .combinedDurationScore:
      return buildCombinedDurationScoreContent(latest: latestSession, sessions: sessions)
    }
  }

  // MARK: - Safe String Formatting

  /// Replaces `%@` placeholders sequentially without `String(format:)` bridging.
  /// Avoids EXC_BAD_ACCESS crashes when Swift Strings cross the CVarArg boundary.
  private static func formatTemplate(_ template: String, _ args: String...) -> String {
    var result = template
    for arg in args {
      if let range = result.range(of: "%@") {
        result.replaceSubrange(range, with: arg)
      }
    }
    return result
  }

  // MARK: - Greeting

  private static func greeting(for date: Date, name: String?) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    let hasName = name != nil && !name!.isEmpty

    switch hour {
    case 5..<12:
      return hasName
        ? formatTemplate(Strings.briefingGreetingMorning, name!)
        : Strings.briefingGreetingMorningNoName
    case 12..<18:
      return hasName
        ? formatTemplate(Strings.briefingGreetingAfternoon, name!)
        : Strings.briefingGreetingAfternoonNoName
    case 18..<23:
      return hasName
        ? formatTemplate(Strings.briefingGreetingEvening, name!)
        : Strings.briefingGreetingEveningNoName
    default:
      return hasName
        ? formatTemplate(Strings.briefingGreetingNight, name!)
        : Strings.briefingGreetingNightNoName
    }
  }

  // MARK: - Score Context

  private static func determineScoreContext(
    sessions: [BriefingSession],
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

  private static func buildHeadline(for session: BriefingSession) -> String {
    let duration = session.totalDuration
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let durationText = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

    let snoringMinutes = Int(session.snoringDuration / 60)
    let score = session.sleepScore

    if snoringMinutes == 0 {
      return formatTemplate(Strings.briefingHeadlineQuiet, durationText)
    }

    return formatTemplate(
      Strings.briefingHeadlineNormal,
      durationText,
      String(snoringMinutes),
      String(score)
    )
  }

  // MARK: - Stats

  private static func buildStats(for session: BriefingSession) -> [BriefingStat] {
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
    sessions: [BriefingSession],
    profile: BriefingProfile?
  ) -> String? {
    guard sessions.count >= 2 else { return nil }

    let latest = sessions[0]
    let latestScore = latest.sleepScore
    let recentScores = sessions.dropFirst().prefix(6).map(\.sleepScore)
    let avg = recentScores.reduce(0, +) / max(recentScores.count, 1)
    let diff = latestScore - avg

    var parts: [String] = []

    if diff > 5 {
      parts.append(formatTemplate(Strings.briefingInsightImproving, String(latestScore), String(avg)))
    } else if diff < -5 {
      parts.append(formatTemplate(Strings.briefingInsightDeclining, String(latestScore), String(avg)))
    } else {
      parts.append(formatTemplate(Strings.briefingInsightSteady, String(avg)))
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
          formatTemplate(
            Strings.briefingInsightGoalShortfall,
            String(avgHours),
            String(avgMinutes),
            String(shortMinutes),
            String(Int(target))
          )
        )
      }
    }

    return parts.joined(separator: " ")
  }

  // MARK: - Weekly Content Builders

  private static func buildWeeklySnoringContent(
    latest: BriefingSession,
    sessions: [BriefingSession]
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    let previous = sessions.dropFirst().prefix(6)
    let avgSnoring = previous.map(\.snoringDuration).reduce(0, +) / Double(max(previous.count, 1))
    let latestMin = Int(latest.snoringDuration / 60)
    let avgMin = Int(avgSnoring / 60)
    let diff = latestMin - avgMin

    let headline = formatTemplate(
      Strings.briefingHeadlineWeeklySnoring,
      String(latestMin),
      String(avgMin)
    )
    let stats = [
      BriefingStat(label: Strings.briefingStatLastNight, value: "\(latestMin)m"),
      BriefingStat(label: Strings.briefingStatWeeklyAvg, value: "\(avgMin)m"),
      BriefingStat(label: Strings.briefingStatTrend, value: diff > 0 ? "+\(diff)m" : "\(diff)m"),
    ]
    let insight = diff > 0
      ? formatTemplate(Strings.briefingInsightWeeklySnoringUp, String(abs(diff)))
      : formatTemplate(Strings.briefingInsightWeeklySnoringDown, String(abs(diff)))

    return (headline, stats, insight)
  }

  private static func buildWeeklyScoreContent(
    latest: BriefingSession,
    sessions: [BriefingSession]
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    let previous = sessions.dropFirst().prefix(6)
    let avgScore = previous.map(\.sleepScore).reduce(0, +) / max(previous.count, 1)
    let diff = latest.sleepScore - avgScore

    let headline = formatTemplate(
      Strings.briefingHeadlineWeeklyScore,
      String(latest.sleepScore),
      String(avgScore)
    )
    let stats = [
      BriefingStat(label: Strings.briefingStatLastNight, value: "\(latest.sleepScore)"),
      BriefingStat(label: Strings.briefingStatWeeklyAvg, value: "\(avgScore)"),
      BriefingStat(label: Strings.briefingStatTrend, value: diff > 0 ? "+\(diff)" : "\(diff)"),
    ]
    let insight = diff > 0
      ? formatTemplate(Strings.briefingInsightWeeklyScoreUp, String(abs(diff)))
      : formatTemplate(Strings.briefingInsightWeeklyScoreDown, String(abs(diff)))

    return (headline, stats, insight)
  }

  private static func buildWeeklyDurationContent(
    latest: BriefingSession,
    sessions: [BriefingSession]
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    let previous = sessions.dropFirst().prefix(6)
    let avgDuration = previous.map(\.totalDuration).reduce(0, +) / Double(max(previous.count, 1))

    let latestHours = Int(latest.totalDuration) / 3600
    let latestMins = (Int(latest.totalDuration) % 3600) / 60
    let latestText = latestHours > 0 ? "\(latestHours)h \(latestMins)m" : "\(latestMins)m"

    let avgHours = Int(avgDuration) / 3600
    let avgMins = (Int(avgDuration) % 3600) / 60
    let avgText = avgHours > 0 ? "\(avgHours)h \(avgMins)m" : "\(avgMins)m"

    let diffMin = Int((latest.totalDuration - avgDuration) / 60)

    let headline = formatTemplate(
      Strings.briefingHeadlineWeeklyDuration,
      latestText,
      avgText
    )
    let stats = [
      BriefingStat(label: Strings.briefingStatLastNight, value: latestText),
      BriefingStat(label: Strings.briefingStatWeeklyAvg, value: avgText),
      BriefingStat(label: Strings.briefingStatTrend, value: diffMin > 0 ? "+\(diffMin)m" : "\(diffMin)m"),
    ]
    let insight = diffMin > 0
      ? formatTemplate(Strings.briefingInsightWeeklyDurationUp, "\(abs(diffMin))m")
      : formatTemplate(Strings.briefingInsightWeeklyDurationDown, "\(abs(diffMin))m")

    return (headline, stats, insight)
  }

  private static func buildCombinedScoreSnoringContent(
    latest: BriefingSession,
    sessions: [BriefingSession]
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    let previous = sessions.dropFirst().prefix(6)
    let avgScore = previous.map(\.sleepScore).reduce(0, +) / max(previous.count, 1)
    let avgSnoring = previous.map(\.snoringDuration).reduce(0, +) / Double(max(previous.count, 1))

    let latestSnoringMin = Int(latest.snoringDuration / 60)
    let avgSnoringMin = Int(avgSnoring / 60)

    let headline = formatTemplate(
      Strings.briefingHeadlineCombinedScoreSnoring,
      String(latest.sleepScore),
      String(avgScore),
      String(latestSnoringMin),
      String(avgSnoringMin)
    )

    let scoreDiff = latest.sleepScore - avgScore
    let stats = [
      BriefingStat(label: Strings.briefingStatScore, value: "\(latest.sleepScore)"),
      BriefingStat(label: Strings.briefingStatSnoring, value: "\(latestSnoringMin)m"),
      BriefingStat(label: Strings.briefingStatTrend, value: scoreDiff > 0 ? "+\(scoreDiff)" : "\(scoreDiff)"),
    ]

    let insight = buildInsight(sessions: sessions, profile: nil)
    return (headline, stats, insight)
  }

  private static func buildCombinedDurationScoreContent(
    latest: BriefingSession,
    sessions: [BriefingSession]
  ) -> (headline: String, stats: [BriefingStat], insight: String?) {
    let previous = sessions.dropFirst().prefix(6)
    let avgScore = previous.map(\.sleepScore).reduce(0, +) / max(previous.count, 1)
    let avgDuration = previous.map(\.totalDuration).reduce(0, +) / Double(max(previous.count, 1))

    let latestHours = Int(latest.totalDuration) / 3600
    let latestMins = (Int(latest.totalDuration) % 3600) / 60
    let latestText = latestHours > 0 ? "\(latestHours)h \(latestMins)m" : "\(latestMins)m"

    let avgHours = Int(avgDuration) / 3600
    let avgMins = (Int(avgDuration) % 3600) / 60
    let avgText = avgHours > 0 ? "\(avgHours)h \(avgMins)m" : "\(avgMins)m"

    let headline = formatTemplate(
      Strings.briefingHeadlineCombinedDurationScore,
      latestText,
      avgText,
      String(latest.sleepScore),
      String(avgScore)
    )

    let durationDiffMin = Int((latest.totalDuration - avgDuration) / 60)
    let stats = [
      BriefingStat(label: Strings.briefingStatSleep, value: latestText),
      BriefingStat(label: Strings.briefingStatScore, value: "\(latest.sleepScore)"),
      BriefingStat(label: Strings.briefingStatTrend, value: durationDiffMin > 0 ? "+\(durationDiffMin)m" : "\(durationDiffMin)m"),
    ]

    let insight = buildInsight(sessions: sessions, profile: nil)
    return (headline, stats, insight)
  }

  // MARK: - Survey

  private static func buildSurvey(
    latestSession: BriefingSession,
    sessions: [BriefingSession],
    lifestyleLogs: [LifestyleLog],
    calendar: Calendar
  ) -> SurveyPrompt? {
    guard sessions.count >= 1 else { return nil }

    let latestScore = latestSession.sleepScore
    let previousSessions = sessions.dropFirst().prefix(6)
    let avg = previousSessions.map(\.sleepScore).reduce(0, +) / max(previousSessions.count, 1)

    // Check if a log already exists for this night
    let nightStart = calendar.startOfDay(for: latestSession.startDate)
    let hasLog = lifestyleLogs.contains { log in
      calendar.isDate(calendar.startOfDay(for: log.date), inSameDayAs: nightStart)
    }
    guard !hasLog else { return nil }

    let isPositive = latestScore >= avg
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
