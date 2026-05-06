import SwiftUI
import Env
import Models
import AudioEngine
import DesignSystem
import Onboarding
import SleepSession
import Statistics
import Recordings
import Settings

extension View {
  func withAppDependencyGraph(
    userPreferences: UserPreferences,
    sessionManager: SessionManager,
    theme: Theme,
    statisticsRouterPath: RouterPath,
    recordingsRouterPath: RouterPath,
    settingsRouterPath: RouterPath
  ) -> some View {
    self
      .environment(userPreferences)
      .environment(sessionManager)
      .environment(theme)
      .environment(statisticsRouterPath)
      .environment(recordingsRouterPath)
      .environment(settingsRouterPath)
  }

  func withEnvironments() -> some View {
    self
      .environment(UserPreferences.shared)
      .environment(SessionManager.shared)
      .environment(Theme.shared)
      .environment(RouterPath())
  }

  func withAppRouter() -> some View {
    self
      .navigationDestination(for: RouterDestination.self) { destination in
        switch destination {
        case .recordingDetail(let id):
          Text("Recording Detail: \(id.uuidString)")
        case .sessionDetail(let id):
          SessionDetailView(sessionID: id)
        case .liveSession:
          SleepSessionView()
        }
      }
  }
}
