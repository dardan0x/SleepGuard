import DesignSystem
import FactoryKit
import Models
import Routing
import SleepCore
import SwiftData
public import SwiftUI

/// The last 7 recorded days. Hosts the shared `LastSevenNightsContent`
/// (ADR 0006) under SleepGuard's toolbar title.
@MainActor
public struct Last7NightsView: View {
  @Injected(\.theme) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  public init() {}

  public var body: some View {
    ScrollView {
      LastSevenNightsContent(stats: stats, trend: ScoreTrend.weekOverWeek(sessions.summariesWithoutEvents)) { night in
        routerPath.navigate(to: .sessionDetail(id: night.id))
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(Strings.statsTrendsLastSevenNights)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
    }
  }

  /// The last 7 recorded days, from SleepCore's rules. Chosen without reading
  /// events, then built in full for those days only.
  private var stats: NightDayStats {
    let chosen = NightDayStats.recent(from: sessions.summariesWithoutEvents).days.flatMap(\.nights)
    return NightDayStats(days: NightDay.days(from: sessions.fullSummaries(of: chosen)))
  }
}
