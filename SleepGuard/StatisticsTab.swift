import Env
import Models
import os
import Personalization
import Routing
import SleepSession
import Statistics
import SwiftData
import SwiftUI

struct StatisticsTab: View {
  @State private var routerPath = RouterPath()
  @State private var showNotificationSoftAsk = false
  let tabCoordinator = TabCoordinator.shared
  let userPreferences = UserPreferences.shared
  let sessionManager = SessionManager.shared
  let sessionCommitter = SessionCommitter.shared
  let appConfig = AppConfig.shared
  let notificationPermissions = NotificationPermissionManager.shared
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
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
        set: { routerPath.presentedSheet = $0 }),
      onDismiss: {
        if sessionManager.completedSession != nil {
          sessionManager.completedSession = nil
        }
      }) { destination in
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
              })
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
      routePendingDeepLink()
    }
    .onChange(of: tabCoordinator.pendingDeepLink) {
      routePendingDeepLink()
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

  /// Consumes a widget deep link. Dropped while recording or while a sheet
  /// (e.g. an unsaved session summary) is up, so neither gets interrupted.
  private func routePendingDeepLink() {
    guard let link = tabCoordinator.pendingDeepLink else { return }
    tabCoordinator.pendingDeepLink = nil
    guard !sessionManager.isRecording, routerPath.presentedSheet == nil else { return }
    DeepLinkRouter.route(link, routerPath: routerPath, modelContext: modelContext)
  }

  private func fetchOrCreateProfile() -> UserProfile? {
    let descriptor = FetchDescriptor<UserProfile>()
    do {
      if let existing = try modelContext.fetch(descriptor).first {
        return existing
      }
    } catch {
      // Don't create a second profile because the first one couldn't be read.
      Log.app.error("Profile fetch failed: \(String(describing: error), privacy: .public)")
      return nil
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
    do {
      try sessionCommitter.commit(session, in: modelContext)
    } catch {
      routerPath.navigateToRoot()
      routerPath.presentedSheet = .sessionSummary
      return
    }
    sessionManager.completedSession = nil
  }
}
