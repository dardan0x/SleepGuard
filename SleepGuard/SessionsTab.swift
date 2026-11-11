import Env
import Models
import Recordings
import Routing
import SwiftUI

struct SessionsTab: View {
  @State private var routerPath = RouterPath()
  let tabCoordinator = TabCoordinator.shared

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
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
