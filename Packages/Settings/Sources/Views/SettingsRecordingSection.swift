import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsRecordingSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  private var sensitivityBinding: Binding<UserPreferences.DetectionSensitivity> {
    Binding(
      get: { userPreferences.detectionSensitivity },
      set: { userPreferences.detectionSensitivity = $0 }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionDetection)
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "waveform", color: theme.accent)
          Text(Strings.settingsSensitivity)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Picker("", selection: sensitivityBinding) {
            Text(Strings.settingsSensitivityLow).tag(UserPreferences.DetectionSensitivity.low)
            Text(Strings.settingsSensitivityMedium).tag(UserPreferences.DetectionSensitivity.medium)
            Text(Strings.settingsSensitivityHigh).tag(UserPreferences.DetectionSensitivity.high)
          }
          .pickerStyle(.segmented)
          .frame(width: 180)
        }
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "bubble.left.fill", color: theme.accent)
          Text(Strings.settingsDetectSleepTalking)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.detectSleepTalking },
            set: { userPreferences.detectSleepTalking = $0 }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        #if DEBUG
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "archivebox.fill", color: theme.accent)
          VStack(alignment: .leading, spacing: 2) {
            Text(Strings.settingsPreserveRawAudio)
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Text(Strings.settingsPreserveRawAudioDescription)
              .font(.system(size: 12))
              .foregroundStyle(theme.textSecondary)
          }
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.preserveRawAudio },
            set: { userPreferences.preserveRawAudio = $0 }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }
        #endif
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
