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
    audioRecorder: AudioRecorder,
    healthKitSync: HealthKitSync,
    watchConnectivityManager: WatchConnectivityManager,
    soundAnalysisDetector: SoundAnalysisDetector,
    soothingMelodyPlayer: SoothingMelodyPlayer,
    appConfig: AppConfig,
    notificationPermissionManager: NotificationPermissionManager
  ) -> some View {
    self
      .environment(userPreferences)
      .environment(sessionManager)
      .environment(theme)
      .environment(audioRecorder)
      .environment(healthKitSync)
      .environment(watchConnectivityManager)
      .environment(soundAnalysisDetector)
      .environment(soothingMelodyPlayer)
      .environment(appConfig)
      .environment(notificationPermissionManager)
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
      .environment(SoothingMelodyPlayer.shared)
      .environment(AppConfig.shared)
      .environment(NotificationPermissionManager.shared)
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
        case .last7Nights:
          Last7NightsView()
        case .calendar:
          CalendarView()
        }
      }
  }
}
