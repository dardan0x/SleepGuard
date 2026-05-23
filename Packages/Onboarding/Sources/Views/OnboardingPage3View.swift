import SwiftUI
import DesignSystem

struct OnboardingPage3View: View {
  let onContinue: () -> Void
  @Environment(Theme.self) private var theme
  @State private var pulseScale: CGFloat = 1.0

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(theme.scoreGreen.opacity(0.15))
          .frame(width: 160, height: 160)
          .scaleEffect(pulseScale)

        Image(systemName: "checkmark.shield.fill")
          .font(.system(size: 72))
          .foregroundStyle(theme.scoreGreen)
          .symbolRenderingMode(.multicolor)
      }
      .onAppear {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
          pulseScale = 1.15
        }
      }

      VStack(spacing: 16) {
        Text(Strings.onboardingPage3Title)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.onboardingPage5Body)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        HStack(spacing: 8) {
          Image(systemName: "lock.shield")
            .font(.system(size: 14))
            .foregroundStyle(theme.scoreGreen)

          Text(Strings.onboardingPage3Badge)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.scoreGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .stroke(theme.scoreGreen.opacity(0.4), lineWidth: 1)
        )
      }

      Spacer()

      Button(action: { onContinue() }) {
        Text(Strings.onboardingPage3Button)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(theme.accent)
          .clipShape(Capsule())
      }
      .buttonStyle(ScaleButtonStyle())
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}
