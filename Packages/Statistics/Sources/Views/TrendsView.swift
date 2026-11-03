import SwiftUI
import SwiftData
import Charts
import Models
import Env
import DesignSystem

@MainActor
public struct TrendsView: View {
    @Environment(Theme.self) private var theme
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
                    totalEvents: totalEvents()
                )
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
    
    private func filteredSessions() -> [SleepSession] {
        let calendar = Calendar.current
        let now = Date()
        let days = timeRange == .week ? 7 : 30
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else {
            return []
        }
        return sessions.filter { $0.startDate >= cutoff }.sorted { $0.startDate < $1.startDate }
    }
    
    private func chartData() -> [TrendBarData] {
        let formatter = timeRange == .week ? DateFormatters.dayOfWeekShort : DateFormatters.dayOfMonth
        
        return filteredSessions().map { session in
            let label = formatter.string(from: session.startDate)
            let minutes = Int(session.snoringDuration / 60)
            let color = maxIntensityColor(for: session)
            return TrendBarData(
                id: session.id,
                label: label,
                minutes: minutes,
                color: color
            )
        }
    }
    
    private func averageSnoringMinutes() -> Int {
        let filtered = filteredSessions()
        guard !filtered.isEmpty else { return 0 }
        let totalMinutes = filtered.reduce(0) { $0 + Int($1.snoringDuration / 60) }
        return totalMinutes / filtered.count
    }
    
    private func averageScore() -> Int {
        let filtered = filteredSessions()
        guard !filtered.isEmpty else { return 0 }
        let total = filtered.reduce(0) { $0 + $1.sleepScore }
        return total / filtered.count
    }
    
    private func bestScore() -> Int {
        filteredSessions().map(\.sleepScore).max() ?? 0
    }
    
    private func worstScore() -> Int {
        filteredSessions().map(\.sleepScore).min() ?? 0
    }
    
    private func totalEvents() -> Int {
        filteredSessions().reduce(0) { $0 + $1.eventsCount }
    }
    
    private func maxIntensityColor(for session: SleepSession) -> Color {
        guard let events = session.events, !events.isEmpty else {
            return theme.snoreQuiet
        }
        let intensities = events.map(\.intensity)
        if intensities.contains(.epic) { return theme.snoreEpic }
        if intensities.contains(.loud) { return theme.snoreLoud }
        if intensities.contains(.light) { return theme.snoreLight }
        return theme.snoreQuiet
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
