import DesignSystem
import FactoryKit
import Services
public import SwiftUI

@MainActor
public struct SleepSessionView: View {
  @Injected(\.sessionManager) private var sessionManager
  @Environment(\.theme) private var theme
  @Injected(\.recordingDelayManager) private var recordingDelayManager

  public init() {}

  public var body: some View {
    ZStack {
      if sessionManager.isRecording {
        BedsideClockView()
      } else if sessionManager.completedSession != nil {
        Color.clear
      } else if recordingDelayManager.isActive {
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
