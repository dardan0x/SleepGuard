import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct SettingsProfileSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(AppConfig.self) private var appConfig
  let onTapProfile: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionProfile)
      VStack(spacing: 16) {
        Button {
          onTapProfile()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "person.fill", color: theme.accent)
            Text(Strings.settingsProfile)
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(theme.textTertiary)
          }
        }
        .buttonStyle(ScaleButtonStyle())

        if appConfig.isEnabled(.sleepBriefing) {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "sunrise.fill", color: theme.accent)
            VStack(alignment: .leading, spacing: 2) {
              Text(Strings.settingsBriefing)
                .font(.system(size: 15))
                .foregroundStyle(theme.textPrimary)
              Text(Strings.settingsBriefingDescription)
                .font(.system(size: 12))
                .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
              get: { userPreferences.briefingEnabled },
              set: { userPreferences.briefingEnabled = $0 }
            ))
            .labelsHidden()
            .tint(theme.scoreGreen)
          }
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
