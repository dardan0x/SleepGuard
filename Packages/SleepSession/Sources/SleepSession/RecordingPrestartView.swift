import SwiftUI
import AudioEngine
import Env
import DesignSystem

@MainActor
struct RecordingPrestartView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  private let audioRecorder = AudioRecorder.shared

  var body: some View {
    ZStack {
      theme.backgroundColor.ignoresSafeArea()

      VStack(spacing: 32) {
        headerView
        micStatusView
        tipsView
        Spacer()
        startButton
      }
      .padding(24)
    }
  }

  private var headerView: some View {
    VStack(spacing: 12) {
      Image(systemName: "moon.fill")
        .font(.system(size: 64))
        .foregroundStyle(theme.primaryColor)

      Text("Ready to Sleep")
        .font(.largeTitle.bold())
        .foregroundStyle(theme.labelColor)

      Text("Track your snoring and improve your sleep quality")
        .font(.subheadline)
        .foregroundStyle(theme.secondaryLabelColor)
        .multilineTextAlignment(.center)
    }
  }

  private var micStatusView: some View {
    HStack(spacing: 12) {
      Image(systemName: audioRecorder.hasPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
        .font(.title2)
        .foregroundStyle(audioRecorder.hasPermission ? theme.secondaryColor : Color.orange)

      VStack(alignment: .leading, spacing: 4) {
        Text(audioRecorder.hasPermission ? "Microphone Ready" : "Microphone Access Needed")
          .font(.headline)
          .foregroundStyle(theme.labelColor)

        Text(audioRecorder.hasPermission ? "We can detect snoring throughout the night" : "Grant access to analyze your sleep sounds")
          .font(.caption)
          .foregroundStyle(theme.secondaryLabelColor)
      }

      Spacer()
    }
    .padding(16)
    .background(theme.surfaceColor)
    .cornerRadius(12)
  }

  private var tipsView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Before You Start")
        .font(.headline)
        .foregroundStyle(theme.labelColor)

      tipRow(icon: "iphone.gen1", text: "Place your phone on a nightstand near your bed")
      tipRow(icon: "bolt.fill", text: "Keep your device plugged in for all-night recording")
      tipRow(icon: "moon.stars.fill", text: "Keep the app open and your screen facing down")
    }
    .padding(16)
    .background(theme.surfaceColor)
    .cornerRadius(12)
  }

  private func tipRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.body)
        .foregroundStyle(theme.primaryColor)
        .frame(width: 24)

      Text(text)
        .font(.subheadline)
        .foregroundStyle(theme.secondaryLabelColor)
        .multilineTextAlignment(.leading)

      Spacer()
    }
  }

  private var startButton: some View {
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
        Image(systemName: "mic.circle.fill")
          .font(.title2)
        Text(audioRecorder.hasPermission ? "Start Recording" : "Grant Access & Start")
          .font(.headline)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(audioRecorder.hasPermission ? theme.primaryColor : Color.orange)
      .foregroundStyle(.white)
      .cornerRadius(12)
    }
  }
}
