import DesignSystem
import Env
import FirebaseCore
import Models
import Onboarding
import SwiftData
import SwiftUI

@main
struct SleepGuardApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @Environment(\.scenePhase) private var scenePhase
  @State private var userPreferences = UserPreferences.shared
  @State private var sessionManager = SessionManager.shared
  @State private var appConfig = AppConfig.shared
  @State private var notificationPermissionManager = NotificationPermissionManager.shared

  init() {
    FirebaseApp.configure()
  }

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
      .overlay {
        UpdateGateView(updateGate: appConfig.updateGate, openAppStore: openAppStore)
      }
      .preferredColorScheme(colorScheme(for: userPreferences.appearance))
      .task {
        await RemoteConfigLoader.shared.refresh()
      }
      .task {
        userPreferences.appOpenCount += 1
        await notificationPermissionManager.refreshStatus()
      }
      .onAppear {
        let container = sharedModelContainer

        // Recover a session left behind by a crash / OOM / background kill:
        // reconstruct it and surface it through the normal summary flow so the
        // user can Save or Discard. Only clean up orphaned files when there is
        // nothing to recover. Deferred to the next tick so the tab observers are
        // registered before `completedSession` changes (which drives the sheet).
        if let snapshot = SessionCheckpointStore.shared.loadIfPresent() {
          Task { @MainActor in
            sessionManager.completedSession = snapshot.makeSession()
          }
        } else {
          PendingSessionStore.shared.cleanupIfNeeded()
        }

        Task.detached {
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

        // Before anything reads cached scores: recompute sessions scored by an
        // older formula/config, so lists and trends never mix two formulas.
        do {
          try SleepSession.refreshStaleCachedScores(in: container.mainContext, config: appConfig.sleepScoreConfig)
        } catch {
          print("[SleepGuardApp] Stale score refresh failed: \(error)")
        }

        WidgetSnapshotWriter.update(modelContext: container.mainContext)
      }
      .onOpenURL { url in
        guard userPreferences.hasCompletedOnboarding, let link = WidgetDeepLink(url: url) else { return }
        TabCoordinator.shared.open(link)
      }
      .onChange(of: sessionManager.isRecording) { _, isRecording in
        UIApplication.shared.isIdleTimerDisabled = isRecording
      }
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active, sessionManager.isRecording {
          UIApplication.shared.isIdleTimerDisabled = true
        }
        if newPhase == .active {
          Task { await RemoteConfigLoader.shared.refresh() }
        }
        if newPhase == .background {
          WidgetSnapshotWriter.update(modelContext: sharedModelContainer.mainContext)
        }
      }
    }
    .modelContainer(sharedModelContainer)
  }

  /// Opens the App Store listing for updates. Replace the ID once the app ships.
  private func openAppStore() {
    // TODO: Replace with the real App Store ID when available.
    guard let url = URL(string: "https://apps.apple.com/app/id000000000") else { return }
    UIApplication.shared.open(url)
  }
}

private func colorScheme(for appearance: UserPreferences.AppearanceSetting) -> ColorScheme? {
  switch appearance {
  case .light: .light
  case .dark: .dark
  case .system: nil
  }
}
