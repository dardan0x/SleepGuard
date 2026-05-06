import SwiftUI
import Env
import SleepSession
import Statistics
import Recordings
import Settings

struct MainTabView: View {
  var body: some View {
    TabView {
      StatisticsTab()
        .tabItem {
          Label("Statistics", systemImage: "chart.bar.fill")
        }

      RecordingsTab()
        .tabItem {
          Label("Media", systemImage: "waveform")
        }

      SettingsTab()
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
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
