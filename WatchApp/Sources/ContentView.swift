import SwiftUI

struct ContentView: View {
  @StateObject private var sessionManager = WatchSessionManager.shared

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        if sessionManager.isRecording {
          recordingView
        } else {
          idleView
        }
      }
      .padding()
    }
  }

  private var idleView: some View {
    VStack(spacing: 20) {
      Image(systemName: "moon.fill")
        .font(.system(size: 48))
        .foregroundStyle(.accent)

      Text("Ready to Sleep")
        .font(.title2.bold())

      Text("Track snoring from your wrist")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button {
        sessionManager.startSession()
      } label: {
        Label("Start Recording", systemImage: "record.circle")
      }
      .buttonStyle(.borderedProminent)
      .tint(.accent)
    }
  }

  private var recordingView: some View {
    VStack(spacing: 16) {
      HStack {
        Image(systemName: "waveform")
          .font(.title2)
          .foregroundStyle(.accent)

        Spacer()

        Text("\(sessionManager.eventsCount) events")
          .font(.caption.bold())
          .foregroundStyle(.green)
      }

      Text(sessionManager.durationString)
        .font(.system(size: 40, weight: .thin, design: .rounded))
        .monospacedDigit()

      Text(sessionManager.statusLabel)
        .font(.caption)
        .foregroundStyle(.secondary)

      Button {
        sessionManager.stopSession()
      } label: {
        Label("Stop", systemImage: "stop.fill")
          .font(.headline)
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
    }
  }
}
