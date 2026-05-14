import SwiftUI
import SwiftData
import Models
import Env
import DesignSystem

@MainActor
public struct Last7NightsView: View {
  @Environment(Theme.self) private var theme
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
          worstDay: worstDay
        )

        allNightsSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
    }
    .background(theme.bgSecondary.ignoresSafeArea())
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
              Text(trend.label)
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

  private var daySummaries: [DaySummary] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: sessions) {
      calendar.startOfDay(for: $0.startDate)
    }

    let sortedDays = grouped.map { date, daySessions in
      DaySummary(date: date, sessions: daySessions)
    }.sorted { $0.date < $1.date }

    return Array(sortedDays.suffix(7))
  }

  private var dateRangeString: String {
    guard let first = daySummaries.first?.date,
          let last = daySummaries.last?.date else { return "" }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return "\(formatter.string(from: first).uppercased()) – \(formatter.string(from: last).uppercased())"
  }

  private var averageSleepScore: Int {
    guard !daySummaries.isEmpty else { return 0 }
    return daySummaries.map(\.avgScore).reduce(0, +) / daySummaries.count
  }

  private var avgSnoringMinutes: Int {
    guard !daySummaries.isEmpty else { return 0 }
    return daySummaries.map(\.totalSnoringMinutes).reduce(0, +) / daySummaries.count
  }

  private var totalEvents: Int {
    daySummaries.map(\.totalEvents).reduce(0, +)
  }

  private var bestScore: Int {
    daySummaries.map(\.avgScore).max() ?? 0
  }

  private var bestDay: String {
    guard let day = daySummaries.max(by: { $0.avgScore < $1.avgScore }) else { return "" }
    return DateFormatters.dayOfWeekShort.string(from: day.date)
  }

  private var worstScore: Int {
    daySummaries.map(\.avgScore).min() ?? 0
  }

  private var worstDay: String {
    guard let day = daySummaries.min(by: { $0.avgScore < $1.avgScore }) else { return "" }
    return DateFormatters.dayOfWeekShort.string(from: day.date)
  }

  private var weekOverWeekTrend: Trend? {
    WeekOverWeekTrendCalculator.trend(for: sessions)
  }
}


