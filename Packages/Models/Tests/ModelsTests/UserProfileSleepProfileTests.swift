import Foundation
import Models
import SleepCore
import Testing

/// The stored profile and the shared `SleepProfile` carry the same values,
/// both ways, and the derived values come from SleepCore's rules.
struct UserProfileSleepProfileTests {
  @Test func mapsEveryFieldBothWays() {
    let bedtime = Date(timeIntervalSinceReferenceDate: 3_600)
    let edited = SleepProfile(
      firstName: "Sam", birthYear: 1990, biologicalSex: .female, heightCm: 170, weightKg: 60,
      targetBedtime: bedtime, targetSleepHours: 8, goal: .snoreLess, caffeine: .heavy, alcohol: .regular,
      exercise: .often, stress: .high, screensBeforeBed: .rarely, hobbies: ["reading"], occupation: .shift)
    let profile = UserProfile()

    profile.sleepProfile = edited

    #expect(profile.sleepProfile == edited)
    #expect(profile.biologicalSex == .female)
    #expect(profile.primaryGoal == .snoreLess)
    #expect(profile.screenBeforeBed == .rarely)
    #expect(profile.occupationType == .shift)
  }

  @Test func defaultsMatch() {
    #expect(UserProfile().sleepProfile == SleepProfile())
  }

  @Test func derivedValuesUseTheSharedRules() {
    let profile = UserProfile(firstName: "Sam", birthYear: 1990)
    #expect(profile.completionPercentage == profile.sleepProfile.completion)
    #expect(profile.age == Calendar.current.component(.year, from: Date()) - 1990)
  }
}
