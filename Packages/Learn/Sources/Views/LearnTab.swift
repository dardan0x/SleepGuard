import DesignSystem
import Env
import Models
import SwiftUI

/// Tab wrapper for the Learn screen. Reads the remote-configured URL from
/// `AppConfig` and falls back to an empty state when none is configured.
public struct LearnTab: View {
  @State private var routerPath = RouterPath()
  @Environment(TabCoordinator.self) private var tabCoordinator
  @Environment(AppConfig.self) private var appConfig
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
      VStack(spacing: 0) {
        titleRow
          .padding(.horizontal, 20)
          .padding(.top, 10)

        content
      }
      .background(theme.bgPrimary)
      .toolbar(.hidden, for: .navigationBar)
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
       let url = URL(string: urlString)
    {
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

  private var titleRow: some View {
    HStack {
      Text(Strings.tabLearn)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      ZStack {
        RoundedRectangle(cornerRadius: 15)
          .fill(theme.accent)
          .frame(width: 30, height: 30)
        Image(systemName: "book.fill")
          .font(.system(size: 16))
          .foregroundStyle(.white)
      }
    }
  }
}
