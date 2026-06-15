import SwiftUI
import SwiftData
import Env
import Models
import Personalization
import SleepSession
import Statistics

struct StatisticsTab: View {
  @State private var routerPath = RouterPath()
  @State private var showNotificationSoftAsk = false
  @Environment(TabCoordinator.self) private var tabCoordinator
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(SessionManager.self) private var sessionManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(AppConfig.self) private var appConfig
  @Environment(NotificationPermissionManager.self) private var notificationPermissions
  @Environment(\.modelContext) private var modelContext


  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      VStack(spacing: 0) {
        ProfilePromptCard {
          routerPath.presentedSheet = .profileEditor
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)

        StatisticsDashboardView()
          .withAppRouter()
      }
      .task {
        await evaluateNotificationSoftAsk()
      }
      .sheet(isPresented: $showNotificationSoftAsk) {
        NotificationSoftAskView(onClose: { showNotificationSoftAsk = false })
          .withEnvironments()
      }
    }
    .sheet(
      item: Binding(
        get: { routerPath.presentedSheet },
        set: { routerPath.presentedSheet = $0 }
      ),
      onDismiss: {
        if sessionManager.completedSession != nil {
          sessionManager.completedSession = nil
        }
      }
    ) { destination in
      switch destination {
      case .sessionSummary:
        if let session = sessionManager.completedSession {
          SessionSummaryView(session: session)
            .withEnvironments()
        }
      case .profileEditor:
        if let profile = fetchOrCreateProfile() {
          ProfileEditorView(
            profile: profile,
            onComplete: {
              routerPath.presentedSheet = nil
              UserPreferences.shared.hasCompletedProfile = true
            },
            onDismiss: {
              routerPath.presentedSheet = nil
            }
          )
          .withEnvironments()
        }
      }
    }
    .onAppear {
      if userPreferences.presentRecordingAfterOnboarding {
        userPreferences.presentRecordingAfterOnboarding = false
        routerPath.navigate(to: .liveSession)
      }
      // Surface a session already set before this tab began observing — e.g. a
      // crash-recovered session restored at launch.
      presentCompletedSessionIfNeeded()
    }
    .onChange(of: sessionManager.completedSession) { _, newValue in
      guard newValue != nil else { return }
      presentCompletedSessionIfNeeded()
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .statistics {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  /// Shows the notification soft-ask after a few app opens, once, if notifications
  /// are remotely enabled and the user hasn't been asked yet.
  private func evaluateNotificationSoftAsk() async {
    guard appConfig.isEnabled(.notifications) else { return }
    guard !userPreferences.notificationSoftAskDismissed else { return }
    guard userPreferences.appOpenCount >= 3 else { return }
    await notificationPermissions.refreshStatus()
    guard notificationPermissions.authorizationStatus == .notDetermined else { return }
    showNotificationSoftAsk = true
  }

  private func fetchOrCreateProfile() -> UserProfile? {
    let descriptor = FetchDescriptor<UserProfile>()
    if let existing = try? modelContext.fetch(descriptor).first {
      return existing
    }
    let profile = UserProfile()
    modelContext.insert(profile)
    return profile
  }

  /// Routes a completed session to the summary sheet, or auto-saves it when it
  /// was force-saved (e.g. low battery). Guards against re-presenting over an
  /// existing sheet so it is safe to call from both `onAppear` and `onChange`.
  private func presentCompletedSessionIfNeeded() {
    guard let session = sessionManager.completedSession else { return }
    guard routerPath.presentedSheet == nil else { return }
    if session.terminationReason != nil {
      autoSaveForceSavedSession(session: session)
    } else {
      routerPath.navigateToRoot()
      routerPath.presentedSheet = .sessionSummary
    }
  }

  private func autoSaveForceSavedSession(session: SleepSession) {
    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    modelContext.insert(session)

    // Cache AFTER insertion so SwiftData tracks the mutations
    session.cachedSleepScore = session.sleepScore
    session.cachedSnoringDuration = session.snoringDuration
    session.hasCachedScore = true

    do {
      try modelContext.save()
    } catch {
      routerPath.navigateToRoot()
      routerPath.presentedSheet = .sessionSummary
      return
    }

    sessionManager.completedSession = nil

    if userPreferences.syncToHealthKit {
      Task {
        healthKitSync.checkAuthorizationStatus()
        await healthKitSync.sync(session: session)
      }
    }
  }
}
