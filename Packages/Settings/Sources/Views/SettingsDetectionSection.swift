import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsDetectionSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  private var sensitivityValue: Binding<Double> {
    Binding {
      switch userPreferences.detectionSensitivity {
      case .low: 0
      case .medium: 1
      case .high: 2
      }
    } set: { newValue in
      switch Int(newValue) {
      case 0: userPreferences.detectionSensitivity = .low
      case 2: userPreferences.detectionSensitivity = .high
      default: userPreferences.detectionSensitivity = .medium
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionDetection)
      VStack(spacing: 16) {
        HStack {
          Text(Strings.settingsSensitivity)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text(userPreferences.detectionSensitivity.displayName)
            .font(.system(size: 15))
            .foregroundStyle(theme.accent)
        }

        HStack(spacing: 8) {
          Text(Strings.settingsSensitivityLow)
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 2)
                .fill(theme.bgElevated)
                .frame(height: 4)
              RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent)
                .frame(width: max(4, (geo.size.width - 20) * (sensitivityValue.wrappedValue / 2) + 10), height: 4)
              Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(radius: 2)
                .offset(x: max(0, (geo.size.width - 20) * (sensitivityValue.wrappedValue / 2)))
            }
          }
          .frame(height: 20)
          Text(Strings.settingsSensitivityHigh)
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
        }

        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "timer", color: theme.accent)
          Text(Strings.settingsMinSnoreDuration)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text("\(Int(userPreferences.minSnoreDuration)) \(Strings.settingsUnitSecondsShort)")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          HStack(spacing: 8) {
            Button {
              if userPreferences.minSnoreDuration > 1 {
                userPreferences.minSnoreDuration -= 1
              }
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 14)
                  .fill(theme.bgElevated)
                  .frame(width: 28, height: 28)
                Text("−")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(theme.textPrimary)
              }
            }
            Button {
              if userPreferences.minSnoreDuration < 10 {
                userPreferences.minSnoreDuration += 1
              }
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 14)
                  .fill(theme.bgElevated)
                  .frame(width: 28, height: 28)
                Text("+")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(theme.textPrimary)
              }
            }
          }
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
