import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SwiftData
import SwiftUI

@MainActor
public struct StatisticsDashboardView: View {
  @Environment(RouterPath.self) private var routerPath
  @Injected(\.theme) private var theme
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var viewState: ViewState = .loading

  public init() {}

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        Color.clear
          .task { loadState() }
      case .empty:
        StatisticsEmptyView(
          theme: theme,
          onStartRecording: { @MainActor in
            routerPath.navigate(to: .liveSession)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          })
      case let .loaded(state):
        StatisticsLoadedView(
          state: state,
          theme: theme,
          onStartRecording: { @MainActor in
            routerPath.navigate(to: .liveSession)
          },
          onViewTrends: {
            routerPath.navigate(to: .trends)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          })
      case .error:
        StatisticsErrorView(theme: theme) {
          loadState()
        }
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .onChange(of: sessions) { _, _ in
      loadState()
    }
  }

  private func loadState() {
    viewState = DashboardState.make(from: sessions, now: Date()).map(ViewState.loaded) ?? .empty
  }

  enum ViewState {
    case loading
    case empty
    case loaded(DashboardState)
    case error
  }
}
