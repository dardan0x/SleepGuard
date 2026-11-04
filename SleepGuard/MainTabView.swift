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
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @Environment(\.modelContext) private var modelContext
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(AppConfig.self) private var appConfig
  @State private var tabCoordinator = TabCoordinator()
  /// Created on first appearance — needs environment-provided
  /// AppConfig/UserPreferences (same two-phase pattern as SessionDetailModel).
  @State private var briefingController: AppBriefingController?

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        systemTabView
      } else {
        customTabView
      }
    }
    .environment(tabCoordinator)
    .onChange(of: appConfig.visibleTabsInOrder) { _, tabs in
      ensureValidSelection(among: tabs)
    }
    .task {
      if briefingController == nil {
        briefingController = AppBriefingController(
          appConfig: appConfig,
          userPreferences: userPreferences)
      }
      briefingController?.generateBriefingIfNeeded(modelContext: modelContext)
    }
    .sheet(
      item: briefingBinding,
      onDismiss: {
        briefingController?.markBriefingShown()
      }) { briefing in
        SleepBriefingView(
          briefing: briefing,
          onDismiss: { briefingController?.dismissBriefing() },
          onChipTap: { chip in
            briefingController?.saveLifestyleLog(chip: chip, briefing: briefing, modelContext: modelContext)
          })
    }
    .overlay {
      SessionProcessingOverlay(isVisible: sessionManager.isProcessingSession)
    }
  }

  private var briefingBinding: Binding<Briefing?> {
    Binding(
      get: { briefingController?.currentBriefing },
      set: { newValue in
        if newValue == nil {
          briefingController?.dismissBriefing()
        }
      })
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
