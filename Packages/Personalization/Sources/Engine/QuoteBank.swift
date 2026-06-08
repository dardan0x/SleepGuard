import Foundation
import DesignSystem

/// Selects a motivational quote by score context.
public enum QuoteBank {
  public static func quote(for trend: ScoreTrend) -> String {
    switch trend {
    case .improving:
      return Strings.briefingQuoteImproving
    case .declining:
      return Strings.briefingQuoteDeclining
    case .steady:
      return Strings.briefingQuoteSteady
    case .firstNight:
      return Strings.briefingQuoteFirstNight
    case .noData:
      return Strings.briefingQuoteNoData
    case .returningAfterGap:
      return Strings.briefingQuoteReturningAfterGap
    }
  }
}
