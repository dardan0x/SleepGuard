import DesignSystem
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
          onStartRecording: { @MainActor in
            routerPath.navigate(to: .liveSession)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          })
      case let .loaded(state):
        StatisticsLoadedView(
          state: state,
          onStartRecording: { @MainActor in
            routerPath.navigate(to: .liveSession)
          },
          onViewTrends: {
            routerPath.navigate(to: .trends)
          },
          onViewCalendar: {
            routerPath.navigate(to: .calendar)
          },
          onViewLastSevenNights: {
            routerPath.navigate(to: .last7Nights)
          })
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    // Not `sessions`: that compares identities, so a night re-scored in
    // place (a formula change at launch, late HealthKit stages) wouldn't
    // redraw. The stamps change whenever a night or its cached score does.
    .onChange(of: scoreStamps) { _, _ in
      loadState()
    }
  }

  /// Cached fields only: reading them doesn't fault events.
  private var scoreStamps: [ScoreStamp] {
    sessions.map { ScoreStamp(id: $0.id, score: $0.cachedSleepScore, version: $0.cachedScoreVersion) }
  }

  private func loadState() {
    viewState = DashboardState.make(from: sessions, now: Date()).map(ViewState.loaded) ?? .empty
  }

  /// No `.error`: `@Query` doesn't surface fetch errors and the dashboard
  /// rules don't throw, so an error state could never be reached.
  enum ViewState {
    case loading
    case empty
    case loaded(DashboardState)
  }
}

/// What the dashboard depends on per night, for change detection.
private struct ScoreStamp: Hashable {
  let id: UUID
  let score: Int
  let version: String
}
