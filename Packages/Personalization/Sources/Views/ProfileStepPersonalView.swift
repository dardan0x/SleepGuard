import DesignSystem
import Models
import SwiftUI

@MainActor
struct ProfileStepPersonalView: View {
  @Bindable var profile: UserProfile
  @Environment(Theme.self) private var theme

  // Local state to avoid writing to @Model on every keystroke
  @State private var hobbiesText: String

  init(profile: UserProfile) {
    self.profile = profile
    _hobbiesText = State(initialValue: profile.hobbies.joined(separator: ", "))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text(Strings.profileEditorStepPersonal)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        hobbiesSection
        occupationSection

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
      profile.hobbies = hobbiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
  }

  private var hobbiesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.profileFieldHobbies)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .lineLimit(1)

      TextField("", text: $hobbiesText)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(theme.textPrimary)
        .padding(14)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusSmall)
    }
  }

  private var occupationSection: some View {
    ProfilePicker(title: Strings.profileFieldOccupation, selection: $profile.occupationType, options: [
      (Strings.profileOccupationDesk, .desk),
      (Strings.profileOccupationActive, .active),
      (Strings.profileOccupationShift, .shift),
      (Strings.profileOccupationOther, .other),
    ])
  }
}
