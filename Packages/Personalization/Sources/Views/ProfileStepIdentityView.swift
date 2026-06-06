import SwiftUI
import Models
import DesignSystem

@MainActor
struct ProfileStepIdentityView: View {
  @Bindable var profile: UserProfile
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(Strings.profileEditorStepYou)
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      ProfileTextField(title: Strings.profileFieldFirstName, text: Binding(
        get: { profile.firstName ?? "" },
        set: { profile.firstName = $0.isEmpty ? nil : $0 }
      ))

      ProfileTextField(title: Strings.profileFieldBirthYear, text: Binding(
        get: { profile.birthYear.map(String.init) ?? "" },
        set: { profile.birthYear = Int($0) }
      ), keyboard: .numberPad)

      ProfilePicker(title: Strings.profileFieldBiologicalSex, selection: $profile.biologicalSex, options: [
        (Strings.profileSexUnspecified, .unspecified),
        (Strings.profileSexFemale, .female),
        (Strings.profileSexMale, .male),
      ])

      ProfileTextField(title: Strings.profileFieldHeight, text: Binding(
        get: { profile.heightCm.map { String(format: "%.0f", $0) } ?? "" },
        set: { profile.heightCm = Double($0) }
      ), keyboard: .decimalPad)

      ProfileTextField(title: Strings.profileFieldWeight, text: Binding(
        get: { profile.weightKg.map { String(format: "%.0f", $0) } ?? "" },
        set: { profile.weightKg = Double($0) }
      ), keyboard: .decimalPad)

      Spacer()
    }
    .padding(.horizontal, 20)
  }
}

@MainActor
struct ProfileTextField: View {
  let title: String
  @Binding var text: String
  var keyboard: UIKeyboardType = .default
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)

      TextField("", text: $text)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(theme.textPrimary)
        .keyboardType(keyboard)
        .padding(14)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusSmall)
    }
  }
}

@MainActor
struct ProfilePicker<T: Hashable & RawRepresentable>: View where T.RawValue: StringProtocol {
  let title: String
  @Binding var selection: T
  let options: [(String, T)]
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)

      Picker("", selection: $selection) {
        ForEach(options, id: \.1) { label, value in
          Text(label).tag(value)
        }
      }
      .pickerStyle(.segmented)
      .colorMultiply(theme.accent)
    }
  }
}
