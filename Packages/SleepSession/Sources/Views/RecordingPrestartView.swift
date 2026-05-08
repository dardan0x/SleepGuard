import SwiftUI
import AudioEngine
import Env
import DesignSystem

@MainActor
struct RecordingPrestartView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @Environment(AudioRecorder.self) private var audioRecorder
  @Environment(AlarmManager.self) private var alarmManager
  @Environment(RouterPath.self) private var routerPath
  @Environment(UserPreferences.self) private var userPreferences

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 32) {
        Spacer()

        iconSection

        headlineSection

        tipsSection

        Spacer()

        actionButtons
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 32)
    }
  }

  private var iconSection: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(theme.bgCard)
      .frame(width: 100, height: 100)
      .overlay(
        Image(systemName: "moon.fill")
          .font(.system(size: 44))
          .foregroundStyle(theme.accent)
      )
  }

  private var headlineSection: some View {
    VStack(spacing: 8) {
      Text("Ready to track your sleep?")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text("We'll listen for snoring through the night. Audio stays on your device.")
        .font(.system(size: 16))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
    }
  }

  private var tipsSection: some View {
    VStack(spacing: 10) {
      tipRow(icon: "iphone", text: "Place your phone on the nightstand")
      tipRow(icon: "bolt.fill", text: "Keep it plugged in")
      tipRow(icon: "bell.slash.fill", text: "Silence notifications")
    }
  }

  private func tipRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(theme.accent)
        .frame(width: 24)

      Text(text)
        .font(.system(size: 16))
        .foregroundStyle(theme.textSecondary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var actionButtons: some View {
    VStack(spacing: 16) {
      alarmSection

      StartRecordingButton(height: 56) {
        Task {
          if !audioRecorder.hasPermission {
            let granted = await audioRecorder.requestPermission()
            guard granted else { return }
          }
          if userPreferences.alarmEnabled {
            alarmManager.setAlarm(
              hour: userPreferences.alarmHour,
              minute: userPreferences.alarmMinute,
              windowMinutes: userPreferences.alarmWindowMinutes
            )
          }
          try? sessionManager.startSession()
        }
      }

      Button {
        routerPath.navigateBack()
      } label: {
        Text("Cancel")
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var alarmSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Toggle("Smart Alarm", isOn: Binding(
          get: { userPreferences.alarmEnabled },
          set: { userPreferences.alarmEnabled = $0 }
        ))
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)
        .tint(theme.scoreGreen)
      }

      if userPreferences.alarmEnabled {
        HStack {
          DatePicker(
            "",
            selection: alarmTimeBinding,
            displayedComponents: .hourAndMinute
          )
          .datePickerStyle(.compact)
          .colorMultiply(theme.textPrimary)

          Spacer()

          Text("\(userPreferences.alarmWindowMinutes) min window")
            .font(.system(size: 13))
            .foregroundStyle(theme.textTertiary)
        }
      }
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var alarmTimeBinding: Binding<Date> {
    Binding {
      var components = DateComponents()
      components.hour = userPreferences.alarmHour
      components.minute = userPreferences.alarmMinute
      return Calendar.current.date(from: components) ?? Date()
    } set: { newDate in
      let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
      userPreferences.alarmHour = components.hour ?? 7
      userPreferences.alarmMinute = components.minute ?? 0
    }
  }
}

