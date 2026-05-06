import SwiftUI
import AudioEngine
import Env
import DesignSystem

@MainActor
struct RecordingPrestartView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @Environment(RouterPath.self) private var routerPath
  private let audioRecorder = AudioRecorder.shared

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 32) {
        Spacer()

        iconSection

        headlineSection

        tipsSection

        Spacer()

        actionButtons
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 32)
    }
  }

  private var iconSection: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(theme.bgCard)
      .frame(width: 100, height: 100)
      .overlay(
        Image(systemName: "moon.fill")
          .font(.system(size: 44))
          .foregroundStyle(theme.accent)
      )
  }

  private var headlineSection: some View {
    VStack(spacing: 8) {
      Text("Ready to track your sleep?")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text("We'll listen for snoring through the night. Audio stays on your device.")
        .font(.system(size: 16))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
    }
  }

  private var tipsSection: some View {
    VStack(spacing: 10) {
      tipRow(icon: "iphone", text: "Place your phone on the nightstand")
      tipRow(icon: "bolt.fill", text: "Keep it plugged in")
      tipRow(icon: "bell.slash.fill", text: "Silence notifications")
    }
  }

  private func tipRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(theme.accent)
        .frame(width: 24)

      Text(text)
        .font(.system(size: 16))
        .foregroundStyle(theme.textSecondary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var actionButtons: some View {
    VStack(spacing: 16) {
      Button {
        Task {
          if !audioRecorder.hasPermission {
            let granted = await audioRecorder.requestPermission()
            guard granted else { return }
          }
          try? sessionManager.startSession()
        }
      } label: {
        HStack(spacing: 8) {
          Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
          Text("Start Recording")
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(theme.accent)
        .clipShape(Capsule())
      }

      Button {
        routerPath.navigateBack()
      } label: {
        Text("Cancel")
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
    }
  }
}
