import SwiftUI
import AudioEngine
import DesignSystem

struct OnboardingPage4View: View {
  let onContinue: () -> Void
  @State private var ringScale1: CGFloat = 1.0
  @State private var ringScale2: CGFloat = 1.0
  @State private var ringOpacity1: Double = 0.6
  @State private var ringOpacity2: Double = 0.3
  @State private var isRequesting = false
  @State private var showGranted = false

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .stroke(Theme.shared.primaryColor.opacity(ringOpacity1), lineWidth: 1)
          .frame(width: 180, height: 180)
          .scaleEffect(ringScale1)

        Circle()
          .stroke(Theme.shared.primaryColor.opacity(ringOpacity2), lineWidth: 1)
          .frame(width: 220, height: 220)
          .scaleEffect(ringScale2)

        Circle()
          .fill(Theme.shared.primaryColor.opacity(0.15))
          .frame(width: 120, height: 120)

        Image(systemName: showGranted ? "checkmark.circle.fill" : "mic.fill")
          .font(.system(size: 40))
          .foregroundStyle(Theme.shared.primaryColor)
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

        if AudioRecorder.shared.hasPermission {
          showGranted = true
        }
      }

      VStack(spacing: 12) {
        Text("We need your\nmicrophone 🎙️")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Theme.shared.labelColor)
          .multilineTextAlignment(.center)

        Text("Only to detect snoring — we're not\neavesdropping on your midnight thoughts.")
          .font(.system(size: 15))
          .foregroundStyle(Theme.shared.secondaryLabelColor)
          .multilineTextAlignment(.center)
      }

      Spacer()

      VStack(spacing: 12) {
        Button {
          Task {
            isRequesting = true
            let granted = await AudioRecorder.shared.requestPermission()
            isRequesting = false
            if granted {
              showGranted = true
            }
            onContinue()
          }
        } label: {
          HStack {
            if isRequesting {
              ProgressView()
                .tint(.white)
            }
            Text(showGranted ? "Microphone ready" : "Yes, listen to my snoring")
              .font(.system(size: 17, weight: .semibold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(showGranted ? Theme.shared.secondaryColor : Theme.shared.primaryColor)
          .clipShape(Capsule())
        }
        .disabled(isRequesting)

        Button("I snore in private") {
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
