import SwiftUI
import DesignSystem

struct OnboardingPage1View: View {
  let onContinue: () -> Void
  @Environment(Theme.self) private var theme
  @State private var zOffset1: CGFloat = 0
  @State private var zOffset2: CGFloat = 0
  @State private var zOpacity1: Double = 0
  @State private var zOpacity2: Double = 0

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.4, green: 0.35, blue: 0.95),
                Color(red: 0.25, green: 0.35, blue: 0.85),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 140, height: 140)
          .shadow(color: Color(red: 0.25, green: 0.35, blue: 0.85).opacity(0.4), radius: 30)

        Text("😴")
          .font(.system(size: 60))

        Text("Z")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.white.opacity(0.8))
          .offset(x: 50, y: -60 + zOffset1)
          .opacity(zOpacity1)

        Text("z")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.white.opacity(0.6))
          .offset(x: 70, y: -80 + zOffset2)
          .opacity(zOpacity2)
      }
      .onAppear {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
          zOffset1 = -12
          zOpacity1 = 1
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
          zOffset2 = -10
          zOpacity2 = 1
        }
      }

      VStack(spacing: 12) {
        Text("Hey 🖐 Ready to\nspy on your sleep?")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text("Don't worry — we're only listening for\nsnores, not secrets.")
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)
      }

      Text("Your snoring finally gets the attention it deserves.")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .fill(theme.accent.opacity(0.15))
        )

      Spacer()

      Button("Let's do this") {
        onContinue()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(theme.accent)
      .clipShape(Capsule())
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 24)
  }
}
