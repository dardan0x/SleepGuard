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
        BedsideClockView()
      } else {
        RecordingPrestartView()
      }
    }
  }
}
