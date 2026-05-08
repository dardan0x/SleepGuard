import SwiftUI
import Env
import DesignSystem
import AudioEngine
import Models

@MainActor
struct AlarmOverlayView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(AlarmManager.self) private var alarmManager
  @Environment(Theme.self) private var theme

  let currentTime: Date
  let onDismiss: () -> Void

  var body: some View {
    ZStack {
      theme.bgPrimary.opacity(0.95).ignoresSafeArea()

      VStack(spacing: 32) {
        Spacer()

        Image(systemName: "alarm.fill")
          .font(.system(size: 64))
          .foregroundStyle(theme.accent)

        Text("Time to Wake Up")
          .font(.system(size: 32, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        Text(timeString)
          .font(.system(size: 64, weight: .thin, design: .rounded))
          .foregroundStyle(theme.accent)
          .monospacedDigit()

        Spacer()

        VStack(spacing: 16) {
          Button {
            alarmManager.clearAlarm()
            _ = sessionManager.stopSession()
            onDismiss()
          } label: {
            Text("I'm Awake")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.accent)
              .clipShape(Capsule())
          }

          Button {
            alarmManager.snooze(minutes: 10)
            onDismiss()
          } label: {
            Text("Snooze 10 min")
              .font(.system(size: 17, weight: .medium))
              .foregroundStyle(theme.textSecondary)
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
    }
  }

  private var timeString: String {
    DateFormatters.time.string(from: currentTime)
  }
}
