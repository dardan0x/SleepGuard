import Foundation
public import SleepCore

/// The stored profile as the shared `SleepProfile` value (the editor and the
/// briefing rules use it). The stored enums stay this module's own, so the
/// schema doesn't change; they map by raw value, which both sides share.
public extension UserProfile {
  var sleepProfile: SleepProfile {
    get {
      SleepProfile(
        firstName: firstName,
        birthYear: birthYear,
        biologicalSex: SleepProfile.BiologicalSex(rawValue: biologicalSex.rawValue) ?? .unspecified,
        heightCm: heightCm,
        weightKg: weightKg,
        targetBedtime: targetBedtime,
        targetSleepHours: targetSleepHours,
        goal: SleepProfile.Goal(rawValue: primaryGoal.rawValue) ?? .wakeRefreshed,
        caffeine: SleepProfile.Caffeine(rawValue: caffeineHabit.rawValue) ?? .moderate,
        alcohol: SleepProfile.Alcohol(rawValue: alcoholHabit.rawValue) ?? .none,
        exercise: SleepProfile.Frequency(rawValue: exerciseFrequency.rawValue) ?? .sometimes,
        stress: SleepProfile.Stress(rawValue: typicalStress.rawValue) ?? .medium,
        screensBeforeBed: SleepProfile.Frequency(rawValue: screenBeforeBed.rawValue) ?? .sometimes,
        hobbies: hobbies,
        occupation: SleepProfile.Occupation(rawValue: occupationType.rawValue) ?? .other)
    }
    set {
      // Only fields that changed are written, so SwiftData sees no edit when
      // nothing changed.
      if firstName != newValue.firstName { firstName = newValue.firstName }
      if birthYear != newValue.birthYear { birthYear = newValue.birthYear }
      if biologicalSex.rawValue != newValue.biologicalSex.rawValue {
        biologicalSex = BiologicalSex(rawValue: newValue.biologicalSex.rawValue) ?? .unspecified
      }
      if heightCm != newValue.heightCm { heightCm = newValue.heightCm }
      if weightKg != newValue.weightKg { weightKg = newValue.weightKg }
      if targetBedtime != newValue.targetBedtime { targetBedtime = newValue.targetBedtime }
      if targetSleepHours != newValue.targetSleepHours { targetSleepHours = newValue.targetSleepHours }
      if primaryGoal.rawValue != newValue.goal.rawValue {
        primaryGoal = PrimaryGoal(rawValue: newValue.goal.rawValue) ?? .wakeRefreshed
      }
      if caffeineHabit.rawValue != newValue.caffeine.rawValue {
        caffeineHabit = CaffeineHabit(rawValue: newValue.caffeine.rawValue) ?? .moderate
      }
      if alcoholHabit.rawValue != newValue.alcohol.rawValue {
        alcoholHabit = AlcoholHabit(rawValue: newValue.alcohol.rawValue) ?? .none
      }
      if exerciseFrequency.rawValue != newValue.exercise.rawValue {
        exerciseFrequency = ExerciseFrequency(rawValue: newValue.exercise.rawValue) ?? .sometimes
      }
      if typicalStress.rawValue != newValue.stress.rawValue {
        typicalStress = TypicalStress(rawValue: newValue.stress.rawValue) ?? .medium
      }
      if screenBeforeBed.rawValue != newValue.screensBeforeBed.rawValue {
        screenBeforeBed = ScreenBeforeBed(rawValue: newValue.screensBeforeBed.rawValue) ?? .sometimes
      }
      if hobbies != newValue.hobbies { hobbies = newValue.hobbies }
      if occupationType.rawValue != newValue.occupation.rawValue {
        occupationType = OccupationType(rawValue: newValue.occupation.rawValue) ?? .other
      }
    }
  }
}
