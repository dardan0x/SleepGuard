import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI

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
          onStartRecording: { @MainActor in
            routerPath.navigate(to: .liveSession)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          })
      case let .loaded(session, dayScore, daySessionCount, recentSessions):
        StatisticsLoadedView(
          session: session,
          dayScore: dayScore,
          daySessionCount: daySessionCount,
          recentSessions: recentSessions,
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
    if let latest = sessions.first {
      let calendar = Calendar.current
      let latestDay = calendar.startOfDay(for: latest.startDate)
      let daySessions = sessions.filter {
        calendar.isDate($0.startDate, inSameDayAs: latestDay)
      }
      let dayScore = daySessions.isEmpty ? latest.sleepScore : daySessions.map(\.sleepScore).reduce(0, +) / daySessions.count
      let recent = Array(sessions.prefix(7))
      viewState = .loaded(session: latest, dayScore: dayScore, daySessionCount: daySessions.count, recentSessions: recent)
    } else {
      viewState = .empty
    }
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(session: SleepSession, dayScore: Int, daySessionCount: Int, recentSessions: [SleepSession])
    case error
  }
}
