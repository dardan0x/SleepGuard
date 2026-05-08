import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsAppearanceSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  let onShowThemePicker: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: "APPEARANCE")
      VStack(spacing: 16) {
        Button {
          onShowThemePicker()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "paintpalette", color: theme.scoreGreen)
            Text("Theme")
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(userPreferences.appearance.displayName)
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
            Image(systemName: "chevron.right")
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
          }
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
