import SwiftUI
import SwiftData
import Env
import Models
import DesignSystem
import Onboarding

@main
struct SnoreGuardApp: App {
  @State private var userPreferences = UserPreferences.shared
  @State private var sessionManager = SessionManager.shared
  @State private var theme = Theme.shared
  @State private var statisticsRouterPath = RouterPath()
  @State private var recordingsRouterPath = RouterPath()
  @State private var settingsRouterPath = RouterPath()

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
      .withAppDependencyGraph(
        userPreferences: userPreferences,
        sessionManager: sessionManager,
        theme: theme,
        statisticsRouterPath: statisticsRouterPath,
        recordingsRouterPath: recordingsRouterPath,
        settingsRouterPath: settingsRouterPath
      )
    }
    .modelContainer(sharedModelContainer)
  }
}
