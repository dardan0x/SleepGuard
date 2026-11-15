import AudioEngine
import DesignSystem
import Env
import FactoryKit
import Models
import SleepCore
import SwiftUI

@MainActor
struct StatisticsLoadedView: View {
  let state: DashboardState
  @Injected(\.theme) private var theme
  @MainActor let onStartRecording: () -> Void
  let onViewTrends: () -> Void
  let onViewCalendar: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      StatisticsLoadedHeaderView(onViewCalendar: onViewCalendar)
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: DeviceSize.isCompactHeight ? 10 : 16) {
          StatisticsWeekSelector(weekDays: weekDays, onViewTrends: onViewTrends)

          SleepScoreGauge(score: state.dayScore, size: 120)

          VStack(spacing: 4) {
            Text(summaryLabel)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(theme.textTertiary)
              .tracking(1)

            Text("\(dateString) · \(timeRangeString)")
              .font(.system(size: 15))
              .foregroundStyle(theme.textSecondary)
          }

          StatisticsStatsGrid(session: session)

          if let stages = session.sleepStageSegments, !stages.isEmpty {
            SleepStageBreakdownView(session: session)
          }

          if !state.recentSessions.isEmpty {
            StatisticsMiniChartSection(recentSessions: state.recentSessions)
          }
        }
        .padding(.horizontal, 20)
      }
      .padding(.top, 10)

      StartRecordingButton(height: 56) {
        onStartRecording()
      }
      .padding(.horizontal, 20)
    }
    .background(theme.bgPrimary.ignoresSafeArea(edges: .bottom))
    .toolbar(.hidden, for: .navigationBar)
  }

  private var summaryLabel: String {
    if state.daySessionCount > 1 {
      return "\(state.daySessionCount) \(Strings.recordingsStatisticsLoadedView)"
    }
    return state.isLastNight
      ? Strings.lastNightStatisticsLoadedView
      : Strings.lastTimeStatisticsLoadedView
  }

  private var session: SleepSession {
    state.session
  }

  private var dateString: String {
    DateFormatters.monthDay.string(from: session.startDate)
  }

  private var timeRangeString: String {
    let start = DateFormatters.timeWithPeriod.string(from: session.startDate)
    if let endDate = session.endDate {
      let end = DateFormatters.timeWithPeriod.string(from: endDate)
      return "\(start) – \(end)"
    }
    return start
  }

  /// Days and levels from SleepCore's week-strip rule; this adds labels and colours.
  private var weekDays: [StatisticsWeekDay] {
    let calendar = Calendar.current
    let weekdaySymbols = calendar.shortWeekdaySymbols

    return state.week.map { day in
      let weekdayIndex = calendar.component(.weekday, from: day.date) - 1
      return StatisticsWeekDay(
        label: String(weekdaySymbols[weekdayIndex].uppercased().prefix(3)),
        number: String(calendar.component(.day, from: day.date)),
        isToday: day.isToday,
        dotColor: day.snoringLevel.map { theme.intensityColor($0) })
    }
  }
}
