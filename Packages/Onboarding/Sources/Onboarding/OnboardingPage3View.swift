import SwiftUI
import DesignSystem

struct OnboardingPage3View: View {
  let onContinue: () -> Void
  @State private var pulseScale: CGFloat = 1.0

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(Theme.shared.secondaryColor.opacity(0.15))
          .frame(width: 160, height: 160)
          .scaleEffect(pulseScale)

        Image(systemName: "checkmark.shield.fill")
          .font(.system(size: 72))
          .foregroundStyle(Theme.shared.secondaryColor)
          .symbolRenderingMode(.multicolor)
      }
      .onAppear {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
          pulseScale = 1.15
        }
      }

      VStack(spacing: 12) {
        Text("We're not that\nkind of app")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Theme.shared.labelColor)
          .multilineTextAlignment(.center)

        Text("Everything is processed on your device.\nNo uploads. No weird cloud stuff.\nNo selling your snore drama.")
          .font(.system(size: 15))
          .foregroundStyle(Theme.shared.secondaryLabelColor)
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 8) {
        Image(systemName: "lock.shield")
          .font(.system(size: 14))
          .foregroundStyle(Theme.shared.secondaryColor)

        Text("Your secrets stay between you and your pillow")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Theme.shared.secondaryColor)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        Capsule()
          .stroke(Theme.shared.secondaryColor.opacity(0.4), lineWidth: 1)
      )

      Spacer()

      Button("I trust you") {
        onContinue()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(Theme.shared.primaryColor)
      .clipShape(Capsule())
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 24)
  }
}
