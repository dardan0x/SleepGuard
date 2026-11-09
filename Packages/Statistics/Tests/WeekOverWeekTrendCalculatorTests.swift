import Testing
@testable import Statistics

struct WeekOverWeekTrendCalculatorTests {
  @Test func noSessionsProducesNoTrend() {
    #expect(WeekOverWeekTrendCalculator.trend(for: []) == nil)
  }
}
