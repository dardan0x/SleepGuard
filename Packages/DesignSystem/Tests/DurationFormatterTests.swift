import Testing
@testable import DesignSystem

struct DurationFormatterTests {
  @Test func underAnHourShowsMinutesOnly() {
    #expect(DurationFormatter.hoursAndMinutes(45) == "45 \(Strings.timeMinutePlural)")
  }
}
