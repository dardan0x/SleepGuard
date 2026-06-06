import Foundation

/// Selects a motivational quote by score context.
/// Returns a human-readable string (will be localized in T5).
public enum QuoteBank {
  public static func quote(for trend: ScoreTrend) -> String {
    switch trend {
    case .improving:
      return "Sleep is the best meditation. Keep the momentum."
    case .declining:
      return "One rough night doesn't define your rest. Try winding down 30 min earlier tonight."
    case .steady:
      return "Good sleep compounds. You're building something."
    case .firstNight:
      return "Here's your first sleep recap. I'll keep learning as you record more nights."
    case .noData:
      return "Record your first night and I'll start learning your sleep."
    case .returningAfterGap:
      return "Welcome back. Let's pick up where you left off."
    }
  }
}
