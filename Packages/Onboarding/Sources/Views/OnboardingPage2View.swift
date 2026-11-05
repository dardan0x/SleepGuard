import DesignSystem
import FactoryKit
import SwiftUI

struct OnboardingPage2View: View {
  let onContinue: () -> Void
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Text(Strings.onboardingPage2Title)
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      VStack(spacing: 12) {
        featureCard(
          icon: "😴",
          title: Strings.onboardingPage2SleepScoreTitle,
          description: Strings.onboardingPage2SleepScoreDescription)
        featureCard(
          icon: "🎤",
          title: Strings.onboardingPage2SnoreDetectionTitle,
          description: Strings.onboardingPage2SnoreDetectionDescription)
        featureCard(
          icon: "📊",
          title: Strings.onboardingPage2SleepTrendsTitle,
          description: Strings.onboardingPage2SleepTrendsDescription)
      }

      Spacer()

      Button(action: { onContinue() }) {
        Text(Strings.onboardingPage1Button)
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
    .padding(.horizontal, 24)
    .padding(.bottom, 40)
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
