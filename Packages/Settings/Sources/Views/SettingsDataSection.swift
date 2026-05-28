import SwiftUI
import SwiftData
import Env
import DesignSystem

@MainActor
struct SettingsDataSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(\.modelContext) private var modelContext
  let onShowDeleteConfirmation: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionData)
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "heart.fill", color: Color(hex: "#FF2D55"))
          Text(Strings.settingsSyncHealth)
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.syncToHealthKit },
            set: { newValue in
              userPreferences.hasExplicitlySetSyncToHealthKit = true
              if newValue {
                Task {
                  let granted = await healthKitSync.requestAuthorization()
                  userPreferences.syncToHealthKit = granted
                }
              } else {
                userPreferences.syncToHealthKit = false
              }
            }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        Button {
          onShowDeleteConfirmation()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "trash", color: theme.destructive)
            Text(Strings.settingsDeleteAll)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(theme.destructive)
            Spacer()
          }
        }
        .buttonStyle(.plain)

        #if DEBUG
        Button {
          MockDataGenerator.generate(modelContext: modelContext)
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "wand.and.stars", color: theme.accent)
            Text("Generate Mock Data")
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(theme.accent)
            Spacer()
          }
        }
        .buttonStyle(.plain)
        #endif
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
