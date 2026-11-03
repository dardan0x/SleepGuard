import SwiftUI
import Env
import Models
import Recordings

struct SessionsTab: View {
  @State private var routerPath = RouterPath()
  @Environment(TabCoordinator.self) private var tabCoordinator

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      RecordingsListView()
        .withAppRouter()
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .sessions {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }
}
