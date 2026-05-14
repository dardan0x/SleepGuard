import SwiftUI
import Env
import Recordings

struct RecordingsTab: View {
  @State private var routerPath = RouterPath()

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      RecordingsListView()
        .withAppRouter()
    }
    .environment(routerPath)
  }
}
