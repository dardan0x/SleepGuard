import SwiftUI
import Env
import DesignSystem

@MainActor
public struct SleepSessionView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    Group {
      if sessionManager.isRecording {
        recordingActiveView
      } else {
        RecordingPrestartView()
      }
    }
  }

  private var recordingActiveView: some View {
    ZStack {
      theme.backgroundColor.ignoresSafeArea()
      VStack(spacing: 16) {
        Image(systemName: "waveform")
          .font(.system(size: 48))
          .foregroundStyle(theme.primaryColor)

        Text("Recording in progress...")
          .font(.title2.bold())
          .foregroundStyle(theme.labelColor)

        Text("Bedside clock UI coming in F2-T4")
          .font(.caption)
          .foregroundStyle(theme.secondaryLabelColor)
      }
    }
  }
}
