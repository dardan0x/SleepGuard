import SwiftUI
import Env
import DesignSystem

@MainActor
struct SettingsAlarmSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  let onShowWindowPicker: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: "ALARM")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          SettingsIconBackground(systemName: "alarm.fill", color: Color(hex: "#FF9F0A"))
          Text("Smart Alarm")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.alarmEnabled },
            set: { userPreferences.alarmEnabled = $0 }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        if userPreferences.alarmEnabled {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "clock", color: theme.accent)
            Text("Alarm time")
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            DatePicker(
              "",
              selection: Binding(
                get: {
                  var components = DateComponents()
                  components.hour = userPreferences.alarmHour
                  components.minute = userPreferences.alarmMinute
                  return Calendar.current.date(from: components) ?? Date()
                },
                set: { newDate in
                  let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                  userPreferences.alarmHour = components.hour ?? 7
                  userPreferences.alarmMinute = components.minute ?? 0
                }
              ),
              displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .colorMultiply(theme.textPrimary)
            .frame(width: 100)
          }

          Button {
            onShowWindowPicker()
          } label: {
            HStack(spacing: 10) {
              SettingsIconBackground(systemName: "scope", color: theme.accent)
              Text("Smart window")
                .font(.system(size: 15))
                .foregroundStyle(theme.textPrimary)
              Spacer()
              Text("\(userPreferences.alarmWindowMinutes) min")
                .font(.system(size: 15))
                .foregroundStyle(theme.textTertiary)
              Image(systemName: "chevron.right")
                .font(.system(size: 15))
                .foregroundStyle(theme.textTertiary)
            }
          }
          .buttonStyle(.plain)
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }
}
