import Testing
@testable import DesignSystem

/// "X h Y min" / "X min" from whole minutes (English values: "h", "min", "mins").
struct DurationFormatterTests {
  @Test(arguments: [
    (0, "0 mins"),
    (1, "1 min"),
    (45, "45 mins"),
    (60, "1h 0 mins"),
    (61, "1h 1 min"),
    (125, "2h 5 mins"),
    (600, "10h 0 mins"),
  ])
  func formatsMinutes(minutes: Int, expected: String) {
    #expect(DurationFormatter.hoursAndMinutes(minutes) == expected)
  }

  @Test func underAnHourShowsMinutesOnly() {
    #expect(DurationFormatter.hoursAndMinutes(45) == "45 \(Strings.timeMinutePlural)")
  }
}
