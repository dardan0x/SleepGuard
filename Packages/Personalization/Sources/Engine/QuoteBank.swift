import DesignSystem
import Foundation

/// Selects a motivational quote by score context.
public enum QuoteBank {
  public static func quote(for trend: ScoreTrend) -> String {
    switch trend {
    case .improving:
      Strings.briefingQuoteImproving
    case .declining:
      Strings.briefingQuoteDeclining
    case .steady:
      Strings.briefingQuoteSteady
    case .firstNight:
      Strings.briefingQuoteFirstNight
    case .noData:
      Strings.briefingQuoteNoData
    case .returningAfterGap:
      Strings.briefingQuoteReturningAfterGap
    }
  }
}
