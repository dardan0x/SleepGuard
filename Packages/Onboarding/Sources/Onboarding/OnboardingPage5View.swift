import SwiftUI
import Env
import DesignSystem

struct OnboardingPage5View: View {
  let onContinue: () -> Void
  @Environment(UserPreferences.self) private var userPreferences

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(Theme.shared.primaryColor.opacity(0.15))
          .frame(width: 140, height: 140)

        Text("🌙")
          .font(.system(size: 60))
      }

      VStack(spacing: 12) {
        Text("Ready for your\nfirst night?")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Theme.shared.labelColor)
          .multilineTextAlignment(.center)

        Text("Place your phone on the nightstand and\nlet us do the rest.")
          .font(.system(size: 15))
          .foregroundStyle(Theme.shared.secondaryLabelColor)
          .multilineTextAlignment(.center)
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
        .background(Theme.shared.primaryColor)
        .clipShape(Capsule())

        Button("Just browsing (for now)") {
          onContinue()
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Theme.shared.secondaryLabelColor)
      }
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 24)
  }
}
