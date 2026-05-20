import SwiftUI
import Env
import DesignSystem

@MainActor
public struct SleepSessionView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    ZStack {
      if sessionManager.isRecording {
        BedsideClockView()
      } else if sessionManager.completedSession != nil {
        Color.clear
      } else if RecordingDelayManager.shared.isActive {
        RecordingCountdownView()
      } else {
        RecordingPrestartView()
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { sessionManager.isLiveSessionVisible = true }
    .onDisappear { sessionManager.isLiveSessionVisible = false }
  }
}
