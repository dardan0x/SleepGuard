import SwiftUI
import Models
import DesignSystem

@MainActor
struct ProfileStepPersonalView: View {
  @Bindable var profile: UserProfile
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text(Strings.profileEditorStepPersonal)
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      hobbiesSection
      occupationSection

      Spacer()
    }
    .padding(.horizontal, 20)
  }

  private var hobbiesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.profileFieldHobbies)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)

      TextField("", text: Binding(
        get: { profile.hobbies.joined(separator: ", ") },
        set: { profile.hobbies = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
      ))
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
