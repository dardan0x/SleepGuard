import Charts
import DesignSystem
import Env
import FactoryKit
import Models
import SleepCore
import SwiftData
import SwiftUI

@MainActor
public struct TrendsView: View {
  @Injected(\.theme) private var theme
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var timeRange: TimeRange = .week

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        timeRangePicker

        snoringMinutesSection

        TrendsChartSection(data: chartData())

        SnoringLegendView()

        TrendsStatsGrid(
          averageScore: averageScore(),
          bestScore: bestScore(),
          worstScore: worstScore(),
          totalEvents: totalEvents())
      }
      .padding(20)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(Strings.statsTrendsTitle)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
    }
  }

  // MARK: - Time Range Picker

  private var timeRangePicker: some View {
    HStack(spacing: 0) {
      ForEach(TimeRange.allCases) { range in
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            timeRange = range
          }
        } label: {
          Text(range.localizedName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(timeRange == range ? .white : theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(timeRange == range ? theme.accent : Color.clear)
            .cornerRadius(8)
        }
      }
    }
    .background(theme.bgCard)
    .cornerRadius(8)
  }

  // MARK: - Snoring Minutes

  private var snoringMinutesSection: some View {
    let avgMinutes = averageSnoringMinutes()

    return VStack(alignment: .leading, spacing: 4) {
      Text(Strings.statsTrendsAvgSnoringLabel)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      HStack(alignment: .lastTextBaseline, spacing: 6) {
        Text(DurationFormatter.hoursAndMinutes(avgMinutes))
          .font(.system(size: 36, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        Text(Strings.statsTrendsAvgMinFormat)
          .font(.system(size: 14))
          .foregroundStyle(theme.textSecondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Data Helpers

  /// The week's or month's nights, from SleepCore's `NightPeriod`. Chosen
  /// without reading events, then built in full for those nights only.
  private var period: NightPeriod {
    let now = Date()
    let days = timeRange == .week ? 7 : 30
    let chosen = NightPeriod(lastDays: days, of: sessions.summariesWithoutEvents, now: now).nights
    return NightPeriod(lastDays: days, of: sessions.fullSummaries(of: chosen), now: now)
  }

  private func chartData() -> [TrendBarData] {
    let formatter = timeRange == .week ? DateFormatters.dayOfWeekShort : DateFormatters.dayOfMonth

    return period.nights.map { night in
      TrendBarData(
        id: night.id,
        label: formatter.string(from: night.start),
        minutes: Int(night.snoringDuration / 60),
        color: theme.intensityColor(night.loudestIntensity ?? .quiet))
    }
  }

  private func averageSnoringMinutes() -> Int {
    period.averageSnoringMinutes
  }

  private func averageScore() -> Int {
    period.averageScore
  }

  private func bestScore() -> Int {
    period.bestScore
  }

  private func worstScore() -> Int {
    period.worstScore
  }

  private func totalEvents() -> Int {
    period.eventCount
  }
}

@MainActor
private enum TimeRange: String, CaseIterable, Identifiable {
  case week = "Week"
  case month = "Month"

  var localizedName: String {
    switch self {
    case .week: Strings.statsTrendsWeek
    case .month: Strings.statsTrendsMonth
    }
  }

  var id: String { rawValue }
}
