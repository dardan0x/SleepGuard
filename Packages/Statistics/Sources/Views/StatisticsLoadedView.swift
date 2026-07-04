import SwiftUI
import AudioEngine
import Env
import Models
import DesignSystem

@MainActor
struct StatisticsLoadedView: View {
    let session: SleepSession
    let dayScore: Int
    let daySessionCount: Int
    let recentSessions: [SleepSession]
    let theme: Theme
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
                    
                    SleepScoreGauge(score: dayScore, theme: theme, size: 120)
                    
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
                        SleepStageBreakdownView(session: session, theme: theme)
                    }
                    
                    if !recentSessions.isEmpty {
                        StatisticsMiniChartSection(recentSessions: recentSessions)
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
        if daySessionCount > 1 {
            return "\(daySessionCount) \(Strings.recordingsStatisticsLoadedView)"
        }
        return isLastNight
            ? Strings.lastNightStatisticsLoadedView
            : Strings.lastTimeStatisticsLoadedView
    }

    private var isLastNight: Bool {
        Calendar.current.isDateInYesterday(session.startDate)
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
    
    private var weekDays: [StatisticsWeekDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekdaySymbols = calendar.shortWeekdaySymbols

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let label = weekdaySymbols[weekdayIndex].uppercased().prefix(3)
            let number = String(calendar.component(.day, from: date))

            let daySession = recentSessions.first { session in
                calendar.isDate(session.startDate, inSameDayAs: date)
            }

            let dotColor: Color? = daySession.map { session in
                let pct = session.snoringPercentage
                if pct > 15 {
                    return theme.snoreLoud
                } else if pct > 5 {
                    return theme.snoreLight
                } else {
                    return theme.snoreQuiet
                }
            }

            return StatisticsWeekDay(
                label: String(label),
                number: number,
                isToday: isToday,
                dotColor: dotColor
            )
        }
    }
}
