import SwiftUI
import Env
import Settings

struct SettingsTab: View {
  @State private var routerPath = RouterPath()

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      SettingsView()
        .withAppRouter()
    }
    .environment(routerPath)
  }
}
