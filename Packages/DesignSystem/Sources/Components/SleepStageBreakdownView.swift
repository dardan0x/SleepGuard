import SwiftUI
import Models
import Env

@MainActor
public struct SleepStageBreakdownView: View {
    public let session: SleepSession
    public let theme: Theme
    @State private var isExpanded: Bool = true
    
    public init(session: SleepSession, theme: Theme) {
        self.session = session
        self.theme = theme
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Strings.statisticsSleepStagesLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(1)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(isExpanded ? Strings.actionCollapse : Strings.actionExpand)
            }
            
            if isExpanded {
                SleepStageHypnogramChart(session: session, theme: theme)
                    .padding(.horizontal, 30)
                legendGrid
                    .padding(.horizontal, 30)
            }
        }
    }
    
    // MARK: - Legend Grid
    
    private var legendGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 10) {
            legendItem(stage: .awake, name: Strings.sleepStageAwake)
            legendItem(stage: .light, name: Strings.sleepStageLightSleep)
            legendItem(stage: .rem, name: Strings.sleepStageRem)
            legendItem(stage: .deep, name: Strings.sleepStageDeepSleep)
        }
    }
    
    private func legendItem(stage: SleepStage, name: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.stageColor(stage))
                .frame(width: 12, height: 12)
            
            Text("\(name): \(durationString(for: stage))")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Helpers
    
    private func durationString(for stage: SleepStage) -> String {
        let minutes = Int(totalDuration(for: stage) / 60)
        return DurationFormatter.hoursAndMinutes(minutes)
    }
    
    private func totalDuration(for stage: SleepStage) -> TimeInterval {
        session.sleepStageSegments?
            .filter { $0.stage == stage }
            .reduce(0) { $0 + $1.duration } ?? 0
    }
}

// MARK: - Shared Hypnogram Chart

@MainActor
public struct SleepStageHypnogramChart: View {
    public let session: SleepSession
    public let theme: Theme
    
    public init(session: SleepSession, theme: Theme) {
        self.session = session
        self.theme = theme
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Canvas { context, size in
                let labelHeight: CGFloat = 16
                let chartHeight = size.height - labelHeight
                let bandHeight = chartHeight / 4
                
                // Background
                let bgRect = CGRect(x: 0, y: 0, width: size.width, height: chartHeight)
                context.fill(
                    Path(roundedRect: bgRect, cornerRadius: 8),
                    with: .color(Color.clear)
                )
                
                // Horizontal grid lines
                for i in 1..<4 {
                    let y = CGFloat(i) * bandHeight
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(theme.border.opacity(0.4)), lineWidth: 0.5)
                }
                
                // Stage segments
                let segments = hypnogramSegments(chartHeight: chartHeight, width: size.width)
                for segment in segments {
                    let rect = CGRect(
                        x: segment.x,
                        y: segment.y,
                        width: max(segment.width, 1),
                        height: bandHeight
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(segment.color)
                    )
                }
                
                // Time labels
                for marker in hourlyMarkers {
                    let text = Text(marker.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textTertiary)
                    let x = CGFloat(marker.ratio) * size.width
                    let clampedX = max(8, min(x, size.width - 8))
                    context.draw(text, at: CGPoint(x: clampedX, y: chartHeight + 10), anchor: .center)
                }
            }
            .frame(height: 100)
        }
    }
    
    // MARK: - Helpers
    
    private func hypnogramSegments(chartHeight: CGFloat, width: CGFloat) -> [HypnogramSegment] {
        guard let stages = session.sleepStageSegments, !stages.isEmpty else { return [] }
        
        let bandHeight = chartHeight / 4
        let totalDuration = max(session.totalDuration, 1)
        
        return stages.map { stage in
            let relativeStart = stage.startOffset / totalDuration
            let relativeDuration = max(stage.duration / totalDuration, 0.001)
            return HypnogramSegment(
                x: CGFloat(relativeStart) * width,
                y: yPosition(for: stage.stage, bandHeight: bandHeight),
                width: CGFloat(relativeDuration) * width,
                color: theme.stageColor(stage.stage)
            )
        }
    }
    
    private func yPosition(for stage: SleepStage, bandHeight: CGFloat) -> CGFloat {
        switch stage {
        case .awake: return 0
        case .rem: return bandHeight
        case .light: return bandHeight * 2
        case .deep: return bandHeight * 3
        }
    }
    
    private var hourlyMarkers: [TimeMarker] {
        let calendar = Calendar.current
        let start = session.startDate
        let end = session.endDate ?? start.addingTimeInterval(session.totalDuration)
        let duration = end.timeIntervalSince(start)
        guard duration > 0 else { return [] }
        
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: start)
        components.hour = (components.hour ?? 0) + 1
        guard var current = calendar.date(from: components) else { return [] }
        
        var markers: [TimeMarker] = []
        while current < end {
            let offset = current.timeIntervalSince(start)
            let ratio = offset / duration
            let hour = calendar.component(.hour, from: current)
            markers.append(TimeMarker(label: String(format: "%02d", hour), ratio: ratio))
            current = current.addingTimeInterval(3600)
        }
        
        return markers
    }
    
    private struct TimeMarker: Hashable {
        let label: String
        let ratio: Double
    }
    
    private struct HypnogramSegment: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let color: Color
    }
}
