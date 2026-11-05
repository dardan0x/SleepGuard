import DesignSystem
import Env
import FactoryKit
import SwiftUI

@MainActor
struct SettingsAboutSection: View {
  @Injected(\.theme) private var theme
  let onRateApp: () -> Void

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionAbout)
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "info.circle.fill", color: Color(hex: "#7C7CFF"))
          Text(Strings.settingsVersion)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text(appVersion)
            .font(.system(size: 15))
            .foregroundStyle(theme.textTertiary)
        }

        Button {
          onRateApp()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "star.fill", color: Color(hex: "#FF9F0A"))
            Text(Strings.settingsRateApp)
              .font(.system(size: 15))
              .foregroundStyle(theme.accent)
            Spacer()
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
