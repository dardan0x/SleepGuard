import SwiftUI
import Env
import Settings

struct SettingsTab: View {
  @State private var routerPath = RouterPath()
  @Environment(TabCoordinator.self) private var tabCoordinator

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      SettingsView()
        .withAppRouter()
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == 2 {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }
}
