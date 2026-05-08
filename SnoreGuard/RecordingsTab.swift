import SwiftUI
import Env
import Recordings

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
