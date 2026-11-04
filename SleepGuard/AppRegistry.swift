import AudioEngine
import DesignSystem
import Env
import Models
import Onboarding
import Recordings
import Settings
import SleepSession
import Statistics
import SwiftUI

extension View {
  func withAppDependencyGraph(
    userPreferences: UserPreferences,
    sessionManager: SessionManager,
    theme: Theme,
    audioRecorder: AudioRecorder,
    healthKitSync: HealthKitSync,
    watchConnectivityManager: WatchConnectivityManager,
    soundAnalysisDetector: SoundAnalysisDetector,
    snoreInterrupterPlayer: SnoreInterrupterPlayer,
    appConfig: AppConfig,
    notificationPermissionManager: NotificationPermissionManager) -> some View
  {
    environment(userPreferences)
      .environment(sessionManager)
      .environment(theme)
      .environment(audioRecorder)
      .environment(healthKitSync)
      .environment(watchConnectivityManager)
      .environment(soundAnalysisDetector)
      .environment(snoreInterrupterPlayer)
      .environment(appConfig)
      .environment(notificationPermissionManager)
  }

  func withEnvironments() -> some View {
    environment(UserPreferences.shared)
      .environment(SessionManager.shared)
      .environment(Theme.shared)
      .environment(AudioRecorder.shared)
      .environment(HealthKitSync.shared)
      .environment(WatchConnectivityManager.shared)
      .environment(SoundAnalysisDetector.shared)
      .environment(SnoreInterrupterPlayer.shared)
      .environment(AppConfig.shared)
      .environment(NotificationPermissionManager.shared)
      .environment(RouterPath())
  }

  func withAppRouter() -> some View {
    navigationDestination(for: RouterDestination.self) { destination in
      switch destination {
      case let .recordingDetail(id):
        SessionDetailView(sessionID: id)
      case let .sessionDetail(id):
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
