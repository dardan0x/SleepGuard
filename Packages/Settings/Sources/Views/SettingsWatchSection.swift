import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

@MainActor
struct SettingsWatchSection: View {
  @Injected(\.theme) private var theme
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.appConfig) private var appConfig
  @Injected(\.watchConnectivityManager) private var watchConnectivityManager
  @Injected(\.healthKitSync) private var healthKitSync

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionWatch)
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "watch.fill", color: theme.accent)
          Text(Strings.watchTitle)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          HStack(spacing: 4) {
            Circle()
              .fill(watchConnectivityManager.isWatchReachable ? theme.scoreGreen : theme.textTertiary)
              .frame(width: 8, height: 8)
            Text(watchConnectivityManager.isWatchReachable ? Strings.watchStatusConnected : Strings.watchStatusNotConnected)
              .font(.system(size: 15))
              .foregroundStyle(watchConnectivityManager.isWatchReachable ? theme.scoreGreen : theme.textTertiary)
          }
        }
        if appConfig.isEnabled(.enhancedSleepTracking) {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "bed.double.fill", color: theme.accent)
            Text(Strings.settingsEnhancedSleepTracking)
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
              get: { userPreferences.enhancedSleepTracking },
              set: { newValue in
                userPreferences.hasExplicitlySetEnhancedSleepTracking = true
                if newValue {
                  Task {
                    let granted = await healthKitSync.requestAuthorization()
                    userPreferences.enhancedSleepTracking = granted
                  }
                } else {
                  userPreferences.enhancedSleepTracking = false
                }
              }
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
