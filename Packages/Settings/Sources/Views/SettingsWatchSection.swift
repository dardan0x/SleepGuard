import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsWatchSection: View {
  @Environment(Theme.self) private var theme
  @Environment(WatchConnectivityManager.self) private var watchConnectivityManager

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: "WATCH")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "watch.fill", color: theme.accent)
          Text("Apple Watch")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          HStack(spacing: 4) {
            Circle()
              .fill(watchConnectivityManager.isWatchReachable ? theme.scoreGreen : theme.textTertiary)
              .frame(width: 8, height: 8)
            Text(watchConnectivityManager.isWatchReachable ? "Connected" : "Not Connected")
              .font(.system(size: 15))
              .foregroundStyle(watchConnectivityManager.isWatchReachable ? theme.scoreGreen : theme.textTertiary)
          }
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
