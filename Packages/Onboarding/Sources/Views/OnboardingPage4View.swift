import AudioEngine
import DesignSystem
import SwiftUI

struct OnboardingPage4View: View {
  let onContinue: () -> Void
  @Environment(AudioRecorder.self) private var audioRecorder
  @Environment(Theme.self) private var theme
  @State private var ringScale1: CGFloat = 1.0
  @State private var ringScale2: CGFloat = 1.0
  @State private var ringOpacity1 = 0.6
  @State private var ringOpacity2 = 0.3
  @State private var isRequesting = false
  @State private var showGranted = false

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .stroke(theme.accent.opacity(ringOpacity1), lineWidth: 1)
          .frame(width: 180, height: 180)
          .scaleEffect(ringScale1)

        Circle()
          .stroke(theme.accent.opacity(ringOpacity2), lineWidth: 1)
          .frame(width: 220, height: 220)
          .scaleEffect(ringScale2)

        Circle()
          .fill(theme.accent.opacity(0.15))
          .frame(width: 120, height: 120)

        Image(systemName: showGranted ? "checkmark.circle.fill" : "mic.fill")
          .font(.system(size: 72))
          .foregroundStyle(theme.accent)
      }
      .onAppear {
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
          ringScale1 = 1.4
          ringOpacity1 = 0
        }
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5)) {
          ringScale2 = 1.4
          ringOpacity2 = 0
        }

        if audioRecorder.hasPermission {
          showGranted = true
        }
      }

      VStack(spacing: 12) {
        Text(Strings.onboardingPage4Title)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.onboardingPage3Body)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)
      }

      Spacer()

      VStack(spacing: 12) {
        Button {
          Task {
            isRequesting = true
            let granted = await audioRecorder.requestPermission()
            isRequesting = false
            if granted {
              showGranted = true
              try? await Task.sleep(for: .seconds(0.8))
            }
            onContinue()
          }
        } label: {
          HStack {
            if isRequesting {
              ProgressView()
                .tint(.white)
            }
            Text(showGranted ? Strings.onboardingPage4Badge : Strings.onboardingPage4ButtonPrimary)
              .font(.system(size: 17, weight: .semibold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(showGranted ? theme.scoreGreen : theme.accent)
          .clipShape(Capsule())
        }
        .disabled(isRequesting)
        .buttonStyle(ScaleButtonStyle())

        Button(action: { onContinue() }) {
          Text(Strings.onboardingPage2Button)
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
