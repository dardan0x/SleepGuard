import DesignSystem
import Env
import Learn
import Models
import Personalization
import Recordings
import Settings
import SleepSession
import Statistics
import SwiftData
import SwiftUI

struct MainTabView: View {
  // Composition root: shared services held directly (same pattern as
  // SleepGuardApp's @State service holdings).
  @State private var theme = AppTheme.shared
  @State private var sessionManager = SessionManager.shared
  @State private var appConfig = AppConfig.shared

  @Environment(\.modelContext) private var modelContext
  @State private var tabCoordinator = TabCoordinator.shared
  /// The morning briefing: shown once per new night, over the tabs.
  @State private var briefingController = BriefingController()

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        systemTabView
      } else {
        customTabView
      }
    }
    .onChange(of: appConfig.visibleTabsInOrder) { _, tabs in
      ensureValidSelection(among: tabs)
    }
    .task {
      briefingController.prepareIfDue(modelContext: modelContext)
    }
    .sheet(item: $briefingController.current, onDismiss: { briefingController.markShown() }) { presented in
      BriefingSheet(presented: presented, controller: briefingController)
    }
    .overlay {
      SessionProcessingOverlay(isVisible: sessionManager.isProcessingSession)
    }
  }

  // MARK: - iOS 26+ (system TabView)

  private var systemTabView: some View {
    TabView(selection: Binding(
      get: { tabCoordinator.selectedTab },
      set: { tabCoordinator.selectTab($0) }))
    {
      ForEach(appConfig.visibleTabsInOrder, id: \.self) { tab in
        view(for: tab)
          .toolbar(sessionManager.isRecording || sessionManager.isLiveSessionVisible ? .hidden : .visible, for: .tabBar)
          .tabItem {
            Label(title(for: tab), systemImage: tab.iconName)
          }
          .tag(tab)
      }
    }
    .tint(theme.accent)
    .animation(nil, value: sessionManager.isLiveSessionVisible)
  }

  // MARK: - iOS < 26 (custom floating tab bar)

  private var customTabView: some View {
    ZStack(alignment: .bottom) {
      customContent
        .padding(.bottom, 60)

      if !sessionManager.isRecording, !sessionManager.isLiveSessionVisible {
        CustomTabBarView(
          tabs: appConfig.visibleTabsInOrder,
          selectedTab: tabCoordinator.selectedTab,
          titleFor: title(for:),
          onSelect: { tab in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
              tabCoordinator.selectTab(tab)
            }
          })
      }
    }
    .ignoresSafeArea(.keyboard)
  }

  @ViewBuilder
  private var customContent: some View {
    ForEach(appConfig.visibleTabsInOrder, id: \.self) { tab in
      view(for: tab)
        .opacity(tabCoordinator.selectedTab == tab ? 1 : 0)
        .allowsHitTesting(tabCoordinator.selectedTab == tab)
    }
  }

  // MARK: - Tab helpers

  @ViewBuilder
  private func view(for tab: AppTab) -> some View {
    switch tab {
    case .statistics: StatisticsTab()
    case .sessions: SessionsTab()
    case .settings: SettingsTab()
    case .learn: LearnTab()
    }
  }

  private func title(for tab: AppTab) -> String {
    switch tab {
    case .statistics: Strings.tabStatistics
    case .sessions: Strings.tabSessions
    case .settings: Strings.tabSettings
    case .learn: Strings.tabLearn
    }
  }

  /// If the currently selected tab is no longer visible (remote config changed),
  /// fall back to the first visible tab.
  private func ensureValidSelection(among tabs: [AppTab]) {
    if !tabs.contains(tabCoordinator.selectedTab) {
      tabCoordinator.selectedTab = tabs.first ?? .statistics
    }
  }
}
