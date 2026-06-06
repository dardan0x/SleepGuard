import Foundation
import Models

public enum ScoreTrend: Sendable {
  case improving
  case declining
  case steady
  case firstNight
  case noData
  case returningAfterGap(days: Int)
}

public struct BriefingStat: Sendable {
  public let label: String
  public let value: String

  public init(label: String, value: String) {
    self.label = label
    self.value = value
  }
}

public struct SurveyPrompt: Sendable {
  public let title: String
  public let chips: [String]
  public let isPositiveSwing: Bool

  public init(title: String, chips: [String], isPositiveSwing: Bool) {
    self.title = title
    self.chips = chips
    self.isPositiveSwing = isPositiveSwing
  }
}

public struct Briefing: Sendable {
  public let greeting: String
  public let headline: String
  public let stats: [BriefingStat]
  public let insight: String?
  public let nudge: String
  public let survey: SurveyPrompt?
  public let scoreContext: ScoreTrend

  public init(
    greeting: String,
    headline: String,
    stats: [BriefingStat],
    insight: String?,
    nudge: String,
    survey: SurveyPrompt?,
    scoreContext: ScoreTrend
  ) {
    self.greeting = greeting
    self.headline = headline
    self.stats = stats
    self.insight = insight
    self.nudge = nudge
    self.survey = survey
    self.scoreContext = scoreContext
  }
}
