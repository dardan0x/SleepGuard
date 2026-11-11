import Models
import SwiftUI

/// Hypnogram chart rendering the session's sleep-stage segments as colored
/// bands (awake/REM/light/deep) with hourly time markers. Shared by the
/// statistics dashboard and the session detail timeline.
@MainActor
public struct SleepStageHypnogramChart: View {
  public let session: SleepSession
  public let theme: any ThemeProviding

  public init(session: SleepSession, theme: any ThemeProviding) {
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
          with: .color(Color.clear))

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
            height: bandHeight)
          context.fill(
            Path(roundedRect: rect, cornerRadius: 2),
            with: .color(segment.color))
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
      .accessibilityElement()
      .accessibilityLabel(Strings.a11ySleepStagesChart)
      .accessibilityValue(stagesSummary)
    }
  }

  /// "Deep 18%, REM 22%, Light 52%, Awake 8%" for VoiceOver.
  private var stagesSummary: String {
    guard let stats = session.stageStats else { return "" }
    return [
      (Strings.sleepStageDeep, stats.deepPct),
      (Strings.sleepStageRem, stats.remPct),
      (Strings.sleepStageLight, stats.lightPct),
      (Strings.sleepStageAwake, stats.awakePct),
    ]
    .map { "\($0) \(Int($1.rounded()))%" }
    .joined(separator: ", ")
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
        color: theme.stageColor(stage.stage))
    }
  }

  private func yPosition(for stage: SleepStage, bandHeight: CGFloat) -> CGFloat {
    switch stage {
    case .awake: 0
    case .rem: bandHeight
    case .light: bandHeight * 2
    case .deep: bandHeight * 3
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
