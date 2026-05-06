import SwiftUI
import DesignSystem

struct OnboardingPage2View: View {
  let onContinue: () -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Text("Here's what we do\nwhile you snooze")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      VStack(spacing: 12) {
        featureCard(
          icon: "😴",
          title: "Sleep Score",
          description: "Get a score for how peacefully you slept (or didn't 😴)"
        )
        featureCard(
          icon: "🎤",
          title: "Snore Detection",
          description: "We detect your snores so you don't have to argue about them."
        )
        featureCard(
          icon: "📊",
          title: "Sleep Trends",
          description: "See if your snoring improves... or if your pillow is the problem."
        )
      }

      Spacer()

      Button("Cool, what else?") {
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

  private func featureCard(icon: String, title: String, description: String) -> some View {
    HStack(spacing: 16) {
      Text(icon)
        .font(.system(size: 28))
        .frame(width: 48, height: 48)
        .background(theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(theme.textPrimary)

        Text(description)
          .font(.system(size: 13))
          .foregroundStyle(theme.textSecondary)
          .lineLimit(2)
      }

      Spacer()
    }
    .padding(16)
    .background(theme.bgCard)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
