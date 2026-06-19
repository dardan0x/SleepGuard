import SwiftUI
import Env
import Models
import DesignSystem

/// Tab wrapper for the Learn screen. Reads the remote-configured URL from
/// `AppConfig` and falls back to an empty state when none is configured.
public struct LearnTab: View {
  @State private var routerPath = RouterPath()
  @Environment(TabCoordinator.self) private var tabCoordinator
  @Environment(AppConfig.self) private var appConfig

  public init() {}

  public var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      content
        .navigationTitle(Strings.tabLearn)
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .learn {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  @ViewBuilder
  private var content: some View {
    if let config = appConfig.learnTabConfig,
       let urlString = config.url,
       let url = URL(string: urlString) {
      LearnView(url: url)
    } else {
      VStack(spacing: 12) {
        Image(systemName: "book.closed")
          .font(.system(size: 48, weight: .medium))
          .foregroundStyle(theme.textTertiary)

        Text(Strings.learnErrorNoContent)
          .font(.system(size: 17))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(theme.bgPrimary)
    }
  }

  @Environment(Theme.self) private var theme
}
