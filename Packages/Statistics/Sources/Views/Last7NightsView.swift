import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SleepCore
import SwiftData
import SwiftUI

@MainActor
public struct Last7NightsView: View {
  @Injected(\.theme) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        dateScoreHeader

        Last7NightsChartCard(days: daySummaries)

        Last7NightsStatGrid(
          avgSnoringMinutes: avgSnoringMinutes,
          totalEvents: totalEvents,
          bestScore: bestScore,
          bestDay: bestDay,
          worstScore: worstScore,
          worstDay: worstDay)

        allNightsSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
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

  // MARK: - Header

  private var dateScoreHeader: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(dateRangeString)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      HStack(alignment: .lastTextBaseline, spacing: 12) {
        Text("\(averageSleepScore)")
          .font(.system(size: 52, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        VStack(alignment: .leading, spacing: 4) {
          Text(Strings.statsLast7nightsAvgSleepScore)
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)

          if let trend = weekOverWeekTrend {
            HStack(spacing: 4) {
              Image(systemName: trend.isPositive ? "arrow.up.forward" : "arrow.down.forward")
                .font(.system(size: 12, weight: .semibold))
              Text(String(format: Strings.statsLast7nightsTrendVsPrevWeek, trend.diff))
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(trend.isPositive ? theme.scoreGreen : theme.scoreRed)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - All Nights Section

  private var allNightsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.statsLast7nightsAllNights)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(0.5)

      VStack(spacing: 8) {
        ForEach(daySummaries.reversed()) { day in
          Last7NightsRow(day: day) {
            // Navigate to session detail for the primary session of this day
            if let sessionId = day.primarySessionId {
              routerPath.navigate(to: .sessionDetail(id: sessionId))
            }
          }
        }
      }
    }
  }

  // MARK: - Data Helpers

  /// The last 7 recorded days, from SleepCore's rules. Chosen without reading
  /// events, then built in full for those days only.
  private var stats: NightDayStats {
    let chosen = NightDayStats.recent(from: sessions.summariesWithoutEvents).days.flatMap(\.nights)
    return NightDayStats(days: NightDay.days(from: sessions.fullSummaries(of: chosen)))
  }

  private var daySummaries: [DaySummary] {
    stats.days.map(DaySummary.init(day:))
  }

  private var dateRangeString: String {
    guard let first = daySummaries.first?.date,
          let last = daySummaries.last?.date else { return "" }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return "\(formatter.string(from: first).uppercased()) – \(formatter.string(from: last).uppercased())"
  }

  private var averageSleepScore: Int {
    stats.averageScore
  }

  private var avgSnoringMinutes: Int {
    stats.averageSnoringMinutes
  }

  private var totalEvents: Int {
    stats.eventCount
  }

  private var bestScore: Int {
    stats.best?.averageScore ?? 0
  }

  private var bestDay: String {
    guard let day = stats.best else { return "" }
    return DateFormatters.dayOfWeekShort.string(from: day.date)
  }

  private var worstScore: Int {
    stats.worst?.averageScore ?? 0
  }

  private var worstDay: String {
    guard let day = stats.worst else { return "" }
    return DateFormatters.dayOfWeekShort.string(from: day.date)
  }

  private var weekOverWeekTrend: Trend? {
    WeekOverWeekTrendCalculator.trend(for: sessions)
  }
}
