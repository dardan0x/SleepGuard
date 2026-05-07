import SwiftUI
import SwiftData
import Env
import Models
import DesignSystem

@MainActor
public struct StatisticsDashboardView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
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
          onStartRecording: {
            routerPath.navigate(to: .liveSession)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          }
        )
      case .loaded(let session, let recentSessions):
        StatisticsLoadedView(
          session: session,
          recentSessions: recentSessions,
          theme: theme,
          onStartRecording: {
            routerPath.navigate(to: .liveSession)
          },
          onViewTrends: {
            routerPath.navigate(to: .trends)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          }
        )
      case .error:
        StatisticsErrorView(theme: theme) {
          loadState()
        }
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
    .onChange(of: sessions) { _, _ in
      loadState()
    }
  }

  private func loadState() {
    if let latest = sessions.first {
      let recent = Array(sessions.prefix(7))
      viewState = .loaded(session: latest, recentSessions: recent)
    } else {
      viewState = .empty
    }
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(session: SleepSession, recentSessions: [SleepSession])
    case error
  }
}
