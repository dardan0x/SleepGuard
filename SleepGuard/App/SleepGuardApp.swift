import Config
import DesignSystem
import FirebaseCore
import Health
import Models
import Onboarding
import os
import Platform
import Routing
import Services
import SleepFiles
import SleepGuardDesignKit
import SleepLogging
import SleepStore
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

  /// Opened once at launch: SleepGuardShared's `SleepStore` in the shared
  /// layout (`Nights.store`), backed up once per version. A store that fails
  /// to open is never deleted: the app runs on an in-memory store and shows
  /// `StoreUnavailableView`, and the file waits for a build that can read it.
  private let storeOpening: SleepStore.Opening = {
    let opening = SleepStore.open(at: SleepGuardStorage.location.storeURL, appVersion: Bundle.main.shortVersionString)
    #if DEBUG
    if opening.failure == nil, ProcessInfo.processInfo.arguments.contains("-generateMockData") {
      MockDataGenerator.generate(modelContext: opening.container.mainContext)
    }
    #endif
    return opening
  }()

  private var sharedModelContainer: ModelContainer { storeOpening.container }

  var body: some Scene {
    WindowGroup {
      Group {
        if storeOpening.failure != nil {
          StoreUnavailableView(openAppStore: openAppStore)
        } else if userPreferences.hasCompletedOnboarding {
          MainTabView()
        } else {
          OnboardingView()
        }
      }
      .overlay {
        UpdateGateView(updateGate: appConfig.updateGate, openAppStore: openAppStore)
      }
      // Every view, ours and the shared kit's, reads its colours from here.
      .environment(\.theme, .sleepGuard)
      .preferredColorScheme(colorScheme(for: userPreferences.appearance))
      .task {
        await RemoteConfigLoader.shared.refresh()
      }
      .task {
        userPreferences.appOpenCount += 1
        await notificationPermissionManager.refreshStatus()
      }
      .onAppear {
        // Nothing reads or writes the in-memory fallback: recovery, cleanup and
        // re-scoring wait for a launch that opens the real store.
        guard storeOpening.failure == nil else { return }
        HealthKitSync.shared.checkAuthorizationStatus()
        if !userPreferences.hasExplicitlySetSyncToHealthKit {
          userPreferences.syncToHealthKit = HealthKitSync.shared.isAuthorized
        }
        if !userPreferences.hasExplicitlySetEnhancedSleepTracking {
          userPreferences.enhancedSleepTracking = HealthKitSync.shared.isAuthorized
        }
      }
      .task {
        guard storeOpening.failure == nil else { return }
        await runLaunchMaintenance()
      }
      .onOpenURL { url in
        guard storeOpening.failure == nil, userPreferences.hasCompletedOnboarding, let link = WidgetDeepLink(url: url) else { return }
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
        if newPhase == .background, storeOpening.failure == nil {
          WidgetSnapshotWriter.update(modelContext: sharedModelContainer.mainContext)
        }
      }
    }
    .modelContainer(sharedModelContainer)
  }

  /// Launch housekeeping, in order: storage limits (fewer nights to re-score),
  /// then re-scoring nights cached by an older formula or config in batches
  /// that yield the main actor (a long history must not stall the first
  /// frames; screens update as batches land), then the widget snapshot from
  /// the fresh scores.
  private func runLaunchMaintenance() async {
    let container = sharedModelContainer
    await StorageLimitEnforcer.shared.enforceLimits(modelContext: container.mainContext)
    do {
      let refreshed = try await NightRecord.refreshStaleSummaries(
        in: container.mainContext, config: appConfig.sleepScoreConfig)
      if refreshed > 0 {
        Log.app.info("Re-scored \(refreshed) night(s) cached by an older formula")
      }
    } catch {
      Log.app.error("Stale score refresh failed: \(String(describing: error), privacy: .public)")
    }
    WidgetSnapshotWriter.update(modelContext: container.mainContext)
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
