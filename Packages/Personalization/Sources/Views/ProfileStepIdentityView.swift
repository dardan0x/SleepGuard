import DesignSystem
import Models
import SwiftUI

@MainActor
struct ProfileStepIdentityView: View {
  @Bindable var profile: UserProfile
  @Environment(Theme.self) private var theme

  // Local state to avoid writing to @Model on every keystroke
  @State private var firstName: String
  @State private var birthYear: String
  @State private var height: String
  @State private var weight: String

  init(profile: UserProfile) {
    self.profile = profile
    _firstName = State(initialValue: profile.firstName ?? "")
    _birthYear = State(initialValue: profile.birthYear.map(String.init) ?? "")
    _height = State(initialValue: profile.heightCm.map { String(format: "%.0f", $0) } ?? "")
    _weight = State(initialValue: profile.weightKg.map { String(format: "%.0f", $0) } ?? "")
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(Strings.profileEditorStepYou)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        ProfileTextField(title: Strings.profileFieldFirstName, text: $firstName)
          .onSubmit { syncFirstName() }

        ProfileTextField(title: Strings.profileFieldBirthYear, text: $birthYear, keyboard: .numberPad)
          .onSubmit { syncBirthYear() }

        ProfilePicker(title: Strings.profileFieldBiologicalSex, selection: $profile.biologicalSex, options: [
          (Strings.profileSexUnspecified, .unspecified),
          (Strings.profileSexFemale, .female),
          (Strings.profileSexMale, .male),
        ])

        ProfileTextField(title: Strings.profileFieldHeight, text: $height, keyboard: .decimalPad)
          .onSubmit { syncHeight() }

        ProfileTextField(title: Strings.profileFieldWeight, text: $weight, keyboard: .decimalPad)
          .onSubmit { syncWeight() }

        Spacer(minLength: 40)
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .contentShape(Rectangle())
      .onTapGesture {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      }
    }
    .scrollIndicators(.hidden)
    .onDisappear {
      syncAll()
    }
  }

  private func syncAll() {
    syncFirstName()
    syncBirthYear()
    syncHeight()
    syncWeight()
  }

  private func syncFirstName() {
    profile.firstName = firstName.isEmpty ? nil : firstName
  }

  private func syncBirthYear() {
    profile.birthYear = Int(birthYear)
  }

  private func syncHeight() {
    profile.heightCm = Double(height)
  }

  private func syncWeight() {
    profile.weightKg = Double(weight)
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
      Text(title.uppercased())
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .lineLimit(1)

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
    VStack(alignment: .leading, spacing: 10) {
      Text(title.uppercased())
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .lineLimit(1)

      FlowLayout(spacing: 8) {
        ForEach(options, id: \.1) { label, value in
          Button {
            selection = value
          } label: {
            Text(label)
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(selection == value ? theme.bgPrimary : theme.textPrimary)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(selection == value ? theme.accent : theme.bgElevated)
              .cornerRadius(theme.radiusSmall)
          }
        }
      }
    }
  }
}
