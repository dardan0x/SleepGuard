import DesignSystem
import Env
import SwiftUI

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
        Text(Strings.onboardingPage5Title)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.onboardingPage2Body)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        Text(Strings.onboardingPrivacyJudgeSilently)
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
        StartRecordingButton(height: 56) {
          userPreferences.presentRecordingAfterOnboarding = true
          onContinue()
        }

        Button(action: { onContinue() }) {
          Text(Strings.onboardingPage4ButtonSecondary)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}
