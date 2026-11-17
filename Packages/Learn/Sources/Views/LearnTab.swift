import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SwiftUI

/// The Learn tab, hosting the shared `LearnContent` with the remote-configured
/// URL (`feature_learn`); no URL shows the shared empty state.
public struct LearnTab: View {
  @State private var routerPath = RouterPath()
  @Injected(\.tabCoordinator) private var tabCoordinator
  @Injected(\.appConfig) private var appConfig

  public init() {}

  public var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
      LearnContent(url: appConfig.learnTabConfig?.url.flatMap(URL.init(string:)))
        .toolbar(.hidden, for: .navigationBar)
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .learn {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }
}
