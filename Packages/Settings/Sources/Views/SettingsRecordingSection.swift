import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsRecordingSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  let onShowClipLengthPicker: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: "RECORDING")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "doc.badge.plus", color: Color(hex: "#FF2D55"))
          Text("Save audio clips")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.saveAudioClips },
            set: { userPreferences.saveAudioClips = $0 }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        Button {
          onShowClipLengthPicker()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "scissors", color: theme.accent)
            Text("Max clip length")
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Text("\(Int(userPreferences.maxClipLength))s")
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
