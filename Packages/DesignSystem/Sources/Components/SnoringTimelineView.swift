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
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 8)
          .fill(theme.bgCard)
          .frame(height: 32)

        ForEach(timelineSegments(in: geometry.size.width), id: \.id) { segment in
          RoundedRectangle(cornerRadius: 2)
            .fill(segment.color)
            .frame(width: segment.width, height: 20)
            .position(x: segment.x + segment.width / 2, y: 16)
        }
      }
      .frame(height: 32)
    }
    .frame(height: 32)
  }

  private var events: [SnoreEvent] {
    session.events?.sorted { $0.timestamp < $1.timestamp } ?? []
  }

  private func timelineSegments(in totalWidth: CGFloat) -> [TimelineSegment] {
    let sessionStart = session.startDate.timeIntervalSinceReferenceDate
    let sessionEnd = session.endDate?.timeIntervalSinceReferenceDate ?? (sessionStart + session.totalDuration)
    let totalDuration = max(sessionEnd - sessionStart, 1)

    return events.map { event in
      let eventStart = event.timestamp.timeIntervalSinceReferenceDate
      let relativeStart = (eventStart - sessionStart) / totalDuration
      let relativeDuration = max(event.duration / totalDuration, 0.002)
      return TimelineSegment(
        id: event.id,
        x: CGFloat(relativeStart) * totalWidth,
        width: max(CGFloat(relativeDuration) * totalWidth, 2),
        color: theme.intensityColor(event.intensity)
      )
    }
  }

  private struct TimelineSegment: Identifiable {
    let id: UUID
    let x: CGFloat
    let width: CGFloat
    let color: Color
  }
}
