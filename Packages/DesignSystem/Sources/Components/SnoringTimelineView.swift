import SwiftUI
import Models
import Env

@MainActor
public struct SnoringTimelineView: View {
  public let session: SleepSession
  public let theme: Theme

  public init(session: SleepSession, theme: Theme) {
    self.session = session
    self.theme = theme
  }

  public var body: some View {
    Canvas { context, size in
      let bgRect = CGRect(x: 0, y: 0, width: size.width, height: 32)
      context.fill(
        Path(roundedRect: bgRect, cornerRadius: 8),
        with: .color(theme.bgCard)
      )

      let segments = timelineSegments(in: size.width)
      for segment in segments {
        let rect = CGRect(x: segment.x, y: 6, width: segment.width, height: 20)
        context.fill(
          Path(roundedRect: rect, cornerRadius: 2),
          with: .color(segment.color)
        )
      }

      // Draw gaps as semi-transparent overlay to indicate detection blind spots
      let gapSegments = gapTimelineSegments(in: size.width)
      for gap in gapSegments {
        let rect = CGRect(x: gap.x, y: 6, width: gap.width, height: 20)
        context.fill(
          Path(roundedRect: rect, cornerRadius: 2),
          with: .color(theme.textTertiary.opacity(0.18))
        )
        context.stroke(
          Path(roundedRect: rect, cornerRadius: 2),
          with: .color(theme.textTertiary.opacity(0.35)),
          lineWidth: 1
        )
      }
    }
    .frame(height: 32)
  }

  private var events: [SnoreEvent] {
    let events = session.events ?? []
    guard events.count > 1 else { return events }
    var isSorted = true
    for i in 1..<events.count {
      if events[i].timestamp < events[i - 1].timestamp {
        isSorted = false
        break
      }
    }
    return isSorted ? events : events.sorted { $0.timestamp < $1.timestamp }
  }

  private func timelineSegments(in totalWidth: CGFloat) -> [TimelineSegment] {
    let sessionStart = session.startDate.timeIntervalSinceReferenceDate
    let sessionEnd = session.endDate?.timeIntervalSinceReferenceDate ?? (sessionStart + session.totalDuration)
    let totalDuration = max(sessionEnd - sessionStart, 1)

    return events.map { event in
      let eventStart = event.timestamp.timeIntervalSinceReferenceDate
      let relativeStart = (eventStart - sessionStart) / totalDuration
      let relativeDuration = max(event.snoreDuration / totalDuration, 0.002)
      return TimelineSegment(
        id: event.id,
        x: CGFloat(relativeStart) * totalWidth,
        width: max(CGFloat(relativeDuration) * totalWidth, 2),
        color: theme.intensityColor(event.intensity)
      )
    }
  }

  private func gapTimelineSegments(in totalWidth: CGFloat) -> [TimelineSegment] {
    let sessionStart = session.startDate.timeIntervalSinceReferenceDate
    let sessionEnd = session.endDate?.timeIntervalSinceReferenceDate ?? (sessionStart + session.totalDuration)
    let totalDuration = max(sessionEnd - sessionStart, 1)

    return session.recordingGaps?.map { gap in
      let relativeStart = gap.startOffset / totalDuration
      let relativeDuration = max(gap.duration / totalDuration, 0.002)
      return TimelineSegment(
        id: UUID(),
        x: CGFloat(relativeStart) * totalWidth,
        width: max(CGFloat(relativeDuration) * totalWidth, 2),
        color: .clear
      )
    } ?? []
  }

  private struct TimelineSegment: Identifiable {
    let id: UUID
    let x: CGFloat
    let width: CGFloat
    let color: Color
  }
}
