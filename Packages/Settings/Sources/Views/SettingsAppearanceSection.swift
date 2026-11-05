import DesignSystem
import Env
import FactoryKit
import SwiftUI

@MainActor
struct SettingsAppearanceSection: View {
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionAppearance)
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "paintpalette", color: theme.scoreGreen)
          Text(Strings.settingsTheme)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text(Strings.settingsThemeAlwaysDark)
            .font(.system(size: 15))
            .foregroundStyle(theme.textTertiary)
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
