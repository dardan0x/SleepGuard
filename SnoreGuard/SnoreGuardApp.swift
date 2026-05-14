import SwiftUI
import SwiftData
import Env
import Models
import AudioEngine
import DesignSystem
import Onboarding

@main
struct SnoreGuardApp: App {
  @State private var userPreferences = UserPreferences.shared
  @State private var sessionManager = SessionManager.shared
  @State private var theme = Theme.shared


  var sharedModelContainer: ModelContainer = {
    let schema = Schema([SleepSession.self, SnoreEvent.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      Group {
        if userPreferences.hasCompletedOnboarding {
          MainTabView()
        } else {
          OnboardingView()
        }
      }
      .preferredColorScheme(colorScheme(for: userPreferences.appearance))
      .withAppDependencyGraph(
        userPreferences: userPreferences,
        sessionManager: sessionManager,
        theme: theme,
        audioRecorder: AudioRecorder.shared,
        healthKitSync: HealthKitSync.shared,
        watchConnectivityManager: WatchConnectivityManager.shared,
        soundAnalysisDetector: SoundAnalysisDetector.shared
      )
    }
    .modelContainer(sharedModelContainer)
  }
}

private func colorScheme(for appearance: UserPreferences.AppearanceSetting) -> ColorScheme? {
  switch appearance {
  case .light: .light
  case .dark: .dark
  case .system: nil
  }
}
