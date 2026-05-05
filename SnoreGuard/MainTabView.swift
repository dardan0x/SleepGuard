import SwiftUI
import Env
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

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      StatisticsDashboardView()
        .withAppRouter()
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
