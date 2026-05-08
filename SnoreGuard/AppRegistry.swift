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
    settingsRouterPath: RouterPath,
    audioRecorder: AudioRecorder,
    healthKitSync: HealthKitSync,
    watchConnectivityManager: WatchConnectivityManager,
    soundAnalysisDetector: SoundAnalysisDetector
  ) -> some View {
    self
      .environment(userPreferences)
      .environment(sessionManager)
      .environment(theme)
      .environment(statisticsRouterPath)
      .environment(recordingsRouterPath)
      .environment(settingsRouterPath)
      .environment(audioRecorder)
      .environment(healthKitSync)
      .environment(watchConnectivityManager)
      .environment(soundAnalysisDetector)
  }

  func withEnvironments() -> some View {
    self
      .environment(UserPreferences.shared)
      .environment(SessionManager.shared)
      .environment(Theme.shared)
      .environment(AudioRecorder.shared)
      .environment(HealthKitSync.shared)
      .environment(WatchConnectivityManager.shared)
      .environment(SoundAnalysisDetector.shared)
      .environment(RouterPath())
  }

  func withAppRouter() -> some View {
    self
      .navigationDestination(for: RouterDestination.self) { destination in
        switch destination {
        case .recordingDetail(let id):
          SessionDetailView(sessionID: id)
        case .sessionDetail(let id):
          SessionDetailView(sessionID: id)
        case .liveSession:
          SleepSessionView()
        case .trends:
          TrendsView()
        case .calendar:
          CalendarView()
        }
      }
  }
}
