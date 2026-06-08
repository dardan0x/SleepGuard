import SwiftUI
import SwiftData
import Env
import Models
import AudioEngine
import DesignSystem
import Onboarding

@main
struct SleepGuardApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var userPreferences = UserPreferences.shared
  @State private var sessionManager = SessionManager.shared
  @State private var theme = Theme.shared


  var sharedModelContainer: ModelContainer = {
    let schema = Schema([SleepSession.self, SnoreEvent.self, UserProfile.self, LifestyleLog.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-generateMockData") {
        MockDataGenerator.generate(modelContext: container.mainContext)
      }
      #endif
      return container
    } catch {
      // If migration fails (e.g. from a dev schema change), delete the store
      // and recreate rather than crashing. User data loss only in dev builds.
      print("[SleepGuardApp] ModelContainer creation failed: \(error). Deleting store and retrying...")
      let storeURL = modelConfiguration.url
      try? FileManager.default.removeItem(at: storeURL)
      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        fatalError("Could not create ModelContainer after store deletion: \(error)")
      }
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
        soundAnalysisDetector: SoundAnalysisDetector.shared,
        soothingMelodyPlayer: SoothingMelodyPlayer.shared
      )
      .onAppear {
        let container = sharedModelContainer
        Task.detached {
          PendingSessionStore.shared.cleanupIfNeeded()
          let context = ModelContext(container)
          await StorageLimitEnforcer.shared.enforceLimits(modelContext: context)
        }

        HealthKitSync.shared.checkAuthorizationStatus()
        if !userPreferences.hasExplicitlySetSyncToHealthKit {
          userPreferences.syncToHealthKit = HealthKitSync.shared.isAuthorized
        }
        if !userPreferences.hasExplicitlySetEnhancedSleepTracking {
          userPreferences.enhancedSleepTracking = HealthKitSync.shared.isAuthorized
        }
      }
      .onChange(of: sessionManager.isRecording) { _, isRecording in
        UIApplication.shared.isIdleTimerDisabled = isRecording
      }
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active && sessionManager.isRecording {
          UIApplication.shared.isIdleTimerDisabled = true
        }
      }
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
