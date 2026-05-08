import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsAboutSection: View {
  @Environment(Theme.self) private var theme
  let onRateApp: () -> Void

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: "ABOUT")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "info.circle.fill", color: Color(hex: "#7C7CFF"))
          Text("Version")
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
            Text("Rate on App Store")
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
