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

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      StatisticsDashboardView()
        .withAppRouter()
    }
    .sheet(item: Binding(
      get: { routerPath.presentedSheet },
      set: { routerPath.presentedSheet = $0 }
    )) { destination in
      switch destination {
      case .sessionSummary:
        Text("Session Summary")
          .withEnvironments()
      case .liveSession:
        SleepSessionView()
          .withEnvironments()
      }
    }
    .onAppear {
      if userPreferences.presentRecordingAfterOnboarding {
        userPreferences.presentRecordingAfterOnboarding = false
        routerPath.presentedSheet = .liveSession
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
