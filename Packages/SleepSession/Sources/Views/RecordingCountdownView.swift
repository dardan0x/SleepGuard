import SwiftUI
import Env
import DesignSystem

@MainActor
struct RecordingCountdownView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Theme.self) private var theme

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        VStack(spacing: 16) {
          Image(systemName: "moon.stars.fill")
            .font(.system(size: 56))
            .foregroundStyle(theme.accent)

          Text("Recording starts in")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(theme.textSecondary)

          Text(RecordingDelayManager.shared.remainingTimeString)
            .font(.system(size: 72, weight: .thin, design: .rounded))
            .foregroundStyle(theme.textPrimary)
            .monospacedDigit()
        }

        Spacer()

        VStack(spacing: 16) {
          Button {
            RecordingDelayManager.shared.cancel()
          } label: {
            Text("Cancel")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(theme.textPrimary)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.bgCard)
              .overlay(
                RoundedRectangle(cornerRadius: 100)
                  .stroke(theme.border, lineWidth: 1)
              )
              .clipShape(Capsule())
          }

          Button {
            RecordingDelayManager.shared.cancel()
            try? sessionManager.startSession()
          } label: {
            Text("Start Now")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.accent)
              .clipShape(Capsule())
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .recordingDelayDidComplete)) { _ in
      try? sessionManager.startSession()
    }
  }
}
