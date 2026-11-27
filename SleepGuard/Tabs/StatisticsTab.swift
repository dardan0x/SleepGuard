import Config
import Models
import os
import Personalization
import Routing
import Services
import Statistics
import SwiftData
import SwiftUI

/// The dashboard tab. The end of a night (summary, auto-save, recovery) and the
/// app-level prompts belong to `SessionFlowHost` at the root, so they work
/// whether or not remote config shows this tab.
struct StatisticsTab: View {
  @State private var routerPath = RouterPath()
  let tabCoordinator = TabCoordinator.shared
  let userPreferences = UserPreferences.shared
  let sessionManager = SessionManager.shared
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
      VStack(spacing: 0) {
        ProfilePromptSection {
          routerPath.presentedSheet = .profileEditor
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)

        StatisticsDashboardView()
          .withAppRouter()
      }
    }
    .sheet(
      item: Binding(
        get: { routerPath.presentedSheet },
        set: { routerPath.presentedSheet = $0 }),
      onDismiss: routePendingDeepLink)
    { destination in
      switch destination {
      case .profileEditor:
        ProfileEditorView(
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
    .onAppear {
      if userPreferences.presentRecordingAfterOnboarding {
        userPreferences.presentRecordingAfterOnboarding = false
        routerPath.navigate(to: .liveSession)
      }
      routePendingDeepLink()
    }
    .onChange(of: tabCoordinator.pendingDeepLink) { routePendingDeepLink() }
    // A link that waited for the night to end is routed once it has.
    .onChange(of: sessionManager.isRecording) { routePendingDeepLink() }
    .onChange(of: sessionManager.completedSession) { routePendingDeepLink() }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .statistics {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  /// Routes a widget deep link. While a night is recording or waiting to be
  /// saved, or this tab shows a sheet, the link waits and is routed afterwards.
  private func routePendingDeepLink() {
    if sessionManager.isRecording, tabCoordinator.pendingDeepLink == .startTracking {
      // Already recording: there is nothing to start, now or after the night.
      _ = tabCoordinator.takePendingDeepLink(blocked: false)
      return
    }
    let blocked = sessionManager.isRecording || sessionManager.completedSession != nil
      || routerPath.presentedSheet != nil
    guard let link = tabCoordinator.takePendingDeepLink(blocked: blocked) else { return }
    DeepLinkRouter.route(link, routerPath: routerPath, modelContext: modelContext)
  }
}
