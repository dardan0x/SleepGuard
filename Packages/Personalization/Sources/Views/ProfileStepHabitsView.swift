import DesignSystem
import FactoryKit
import Models
import SwiftUI

@MainActor
struct ProfileStepHabitsView: View {
  @Bindable var profile: UserProfile
  @Injected(\.theme) private var theme

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text(Strings.profileEditorStepHabits)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        ProfileChipSelector(
          title: Strings.profileFieldCaffeine,
          options: caffeineLabels,
          selection: Binding(
            get: { caffeineLabels[safe: caffeineIndex] ?? caffeineLabels[2] },
            set: { profile.caffeineHabit = caffeineValues[safe: caffeineLabels.firstIndex(of: $0) ?? 2] ?? .moderate }))

        ProfileChipSelector(
          title: Strings.profileFieldAlcohol,
          options: alcoholLabels,
          selection: Binding(
            get: { alcoholLabels[safe: alcoholIndex] ?? alcoholLabels[0] },
            set: { profile.alcoholHabit = alcoholValues[safe: alcoholLabels.firstIndex(of: $0) ?? 0] ?? .none }))

        ProfileChipSelector(
          title: Strings.profileFieldExercise,
          options: frequencyLabels,
          selection: Binding(
            get: { frequencyLabels[safe: exerciseIndex] ?? frequencyLabels[1] },
            set: { profile.exerciseFrequency = exerciseValues[safe: frequencyLabels.firstIndex(of: $0) ?? 1] ?? .sometimes }))

        ProfileChipSelector(
          title: Strings.profileFieldStress,
          options: stressLabels,
          selection: Binding(
            get: { stressLabels[safe: stressIndex] ?? stressLabels[1] },
            set: { profile.typicalStress = stressValues[safe: stressLabels.firstIndex(of: $0) ?? 1] ?? .medium }))

        ProfileChipSelector(
          title: Strings.profileFieldScreens,
          options: screenLabels,
          selection: Binding(
            get: { screenLabels[safe: screenIndex] ?? screenLabels[1] },
            set: { profile.screenBeforeBed = screenValues[safe: screenLabels.firstIndex(of: $0) ?? 1] ?? .sometimes }))

        Spacer(minLength: 40)
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
    }
    .scrollIndicators(.hidden)
  }

  // MARK: - Caffeine

  private var caffeineLabels: [String] {
    [Strings.profileHabitCaffeineNone, Strings.profileHabitCaffeineLight, Strings.profileHabitCaffeineModerate, Strings.profileHabitCaffeineHeavy]
  }

  private var caffeineValues: [CaffeineHabit] { [.none, .light, .moderate, .heavy] }
  private var caffeineIndex: Int { caffeineValues.firstIndex(of: profile.caffeineHabit) ?? 2 }

  // MARK: - Alcohol

  private var alcoholLabels: [String] {
    [Strings.profileHabitAlcoholNone, Strings.profileHabitAlcoholOccasional, Strings.profileHabitAlcoholRegular]
  }

  private var alcoholValues: [AlcoholHabit] { [.none, .occasional, .regular] }
  private var alcoholIndex: Int { alcoholValues.firstIndex(of: profile.alcoholHabit) ?? 0 }

  // MARK: - Exercise

  private var frequencyLabels: [String] {
    [Strings.profileFrequencyRarely, Strings.profileFrequencySometimes, Strings.profileFrequencyOften]
  }

  private var frequencyValues: [ExerciseFrequency] { [.rarely, .sometimes, .often] }
  private var exerciseIndex: Int { frequencyValues.firstIndex(of: profile.exerciseFrequency) ?? 1 }
  private var exerciseValues: [ExerciseFrequency] { frequencyValues }

  // MARK: - Stress

  private var stressLabels: [String] {
    [Strings.profileStressLow, Strings.profileStressMedium, Strings.profileStressHigh]
  }

  private var stressValues: [TypicalStress] { [.low, .medium, .high] }
  private var stressIndex: Int { stressValues.firstIndex(of: profile.typicalStress) ?? 1 }

  // MARK: - Screens

  private var screenLabels: [String] {
    [Strings.profileScreenRarely, Strings.profileScreenSometimes, Strings.profileScreenOften]
  }

  private var screenValues: [ScreenBeforeBed] { [.rarely, .sometimes, .often] }
  private var screenIndex: Int { screenValues.firstIndex(of: profile.screenBeforeBed) ?? 1 }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
