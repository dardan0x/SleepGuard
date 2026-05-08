import SwiftUI
import Env
import DesignSystem
import SleepSession
import Statistics
import Recordings
import Settings

struct MainTabView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @State private var selectedTab = 0

  var body: some View {
    if #available(iOS 26.0, *) {
      systemTabView
    } else {
      customTabView
    }
  }

  // MARK: - iOS 26+ (system TabView)

  private var systemTabView: some View {
    TabView {
      StatisticsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label("Statistics", systemImage: "chart.bar.fill")
        }

      RecordingsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label("Media", systemImage: "waveform")
        }

      SettingsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
    .tint(theme.accent)
    .toolbarBackground(theme.bgSecondary, for: .tabBar)
  }

  // MARK: - iOS < 26 (custom floating tab bar)

  private var customTabView: some View {
    ZStack(alignment: .bottom) {
      customContent

      if !sessionManager.isRecording {
        customTabBar
      }
    }
    .ignoresSafeArea(.keyboard)
  }

  @ViewBuilder
  private var customContent: some View {
    StatisticsTab()
      .opacity(selectedTab == 0 ? 1 : 0)
      .allowsHitTesting(selectedTab == 0)

    RecordingsTab()
      .opacity(selectedTab == 1 ? 1 : 0)
      .allowsHitTesting(selectedTab == 1)

    SettingsTab()
      .opacity(selectedTab == 2 ? 1 : 0)
      .allowsHitTesting(selectedTab == 2)
  }

  private var customTabBar: some View {
    VStack(spacing: 0) {
      Spacer()

      HStack(spacing: 4) {
        tabItem(index: 0, icon: "chart.bar.fill", label: "STATISTICS")
        tabItem(index: 1, icon: "waveform", label: "MEDIA")
        tabItem(index: 2, icon: "gearshape", label: "SETTINGS")
      }
      .padding(4)
      .background(theme.bgCard)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(theme.border, lineWidth: 1)
      )
      .padding(.horizontal, 21)
      .padding(.bottom, 12)
      .padding(.top, 12)
      .background(theme.bgSecondary.ignoresSafeArea(edges: .bottom))
    }
  }

  private func tabItem(index: Int, icon: String, label: String) -> some View {
    let isSelected = selectedTab == index

    return Button {
      withAnimation(.spring(duration: 0.3)) {
        selectedTab = index
      }
    } label: {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))

        Text(label)
          .font(.system(size: 10, weight: .semibold))
          .tracking(0.5)
      }
      .foregroundStyle(isSelected ? theme.textPrimary : theme.tabInactive)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(isSelected ? theme.accent : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 26))
    }
    .buttonStyle(.plain)
  }
}

struct StatisticsTab: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(SessionManager.self) private var sessionManager

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      StatisticsDashboardView()
        .withAppRouter()
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
      }
    }
    .onAppear {
      if userPreferences.presentRecordingAfterOnboarding {
        userPreferences.presentRecordingAfterOnboarding = false
        routerPath.navigate(to: .liveSession)
      }
    }
    .onChange(of: sessionManager.completedSession) { _, newValue in
      if newValue != nil {
        routerPath.navigateToRoot()
        routerPath.presentedSheet = .sessionSummary
      }
    }
  }
}

struct RecordingsTab: View {
  @Environment(RouterPath.self) private var routerPath

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      RecordingsListView()
        .withAppRouter()
    }
  }
}

struct SettingsTab: View {
  @Environment(RouterPath.self) private var routerPath

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      SettingsView()
        .withAppRouter()
    }
  }
}
