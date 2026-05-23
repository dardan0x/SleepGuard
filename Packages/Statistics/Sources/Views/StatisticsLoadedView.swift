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
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                StatisticsLoadedHeaderView(onViewCalendar: onViewCalendar)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: DeviceSize.isCompactHeight ? 10 : 16) {
                        StatisticsWeekSelector(weekDays: weekDays, onViewTrends: onViewTrends)
                        
                        SleepScoreGauge(score: dayScore, theme: theme, size: 120)
                        
                        VStack(spacing: 4) {
                            Text(daySessionCount > 1 ? "\(daySessionCount) \(Strings.recordingsStatisticsLoadedView)" : "\(Strings.lastNightStatisticsLoadedView)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textTertiary)
                                .tracking(1)
                            
                            Text("\(dateString) · \(timeRangeString)")
                                .font(.system(size: 15))
                                .foregroundStyle(theme.textSecondary)
                        }
                        
                        StatisticsStatsGrid(session: session)
                        
                        if !recentSessions.isEmpty {
                            StatisticsMiniChartSection(recentSessions: recentSessions)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
            }
            
            StartRecordingButton(height: 56) {
                onStartRecording()
            }
            .padding(.horizontal, 20)
            .background(theme.bgPrimary.ignoresSafeArea(edges: .bottom))
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
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
            return StatisticsWeekDay(label: String(label), number: number, isToday: isToday)
        }
    }
}
