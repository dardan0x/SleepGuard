import Foundation
import Testing
@testable import DesignSystem

/// Last 7 Nights week-over-week label: the view formats `Trend.diff` with this key.
struct TrendLabelFormatTests {
  @Test(arguments: [(5, "+5 vs prev wk"), (-3, "-3 vs prev wk")])
  func labelIsSigned(diff: Int, expected: String) {
    #expect(String(format: Strings.statsLast7nightsTrendVsPrevWeek, diff) == expected)
  }
}
