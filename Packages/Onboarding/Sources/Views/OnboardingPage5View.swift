import SwiftUI
import Env
import DesignSystem

struct OnboardingPage5View: View {
  let onContinue: () -> Void
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(theme.accent.opacity(0.15))
          .frame(width: 140, height: 140)

        Text("🌙")
          .font(.system(size: 60))
      }

      VStack(spacing: 16) {
        Text("Ready for your\nfirst night?")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text("Place your phone on the nightstand and\nlet us do the rest.")
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        Text("Don't worry — we'll judge your snoring silently.")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(
            Capsule()
              .fill(theme.bgElevated)
          )
      }

      Spacer()

      VStack(spacing: 12) {
        Button("Start Recording") {
          userPreferences.presentRecordingAfterOnboarding = true
          onContinue()
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(theme.accent)
        .clipShape(Capsule())

        Button("Just browsing (for now)") {
          onContinue()
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(theme.textSecondary)
      }
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}
