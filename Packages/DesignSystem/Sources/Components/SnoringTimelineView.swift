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
    .frame(height: 34)
  }

  /// Timeline items: snoring episodes merged, other categories raw.
  private var timelineItems: [TimelineItem] {
    var items: [TimelineItem] = []

    // Add snoring episodes
    for episode in session.displayableSnoringEpisodes {
      items.append(TimelineItem(
        id: episode.id,
        timestamp: episode.startTime,
        duration: episode.snoreDuration,
        intensity: episode.intensity,
        category: .snoring
      ))
    }

    // Add non-snoring events individually
    let otherEvents = (session.events ?? [])
      .filter { $0.category != .snoring }
      .sorted(by: { $0.timestamp < $1.timestamp })
    for event in otherEvents {
      items.append(TimelineItem(
        id: event.id,
        timestamp: event.timestamp,
        duration: event.snoreDuration,
        intensity: event.intensity,
        category: event.category
      ))
    }

    return items.sorted(by: { $0.timestamp < $1.timestamp })
  }

  private func timelineSegments(in totalWidth: CGFloat) -> [TimelineSegment] {
    let sessionStart = session.startDate.timeIntervalSinceReferenceDate
    let sessionEnd = session.endDate?.timeIntervalSinceReferenceDate ?? (sessionStart + session.totalDuration)
    let totalDuration = max(sessionEnd - sessionStart, 1)

    return timelineItems.map { item in
      let itemStart = item.timestamp.timeIntervalSinceReferenceDate
      let relativeStart = (itemStart - sessionStart) / totalDuration
      let relativeDuration = max(item.duration / totalDuration, 0.002)
      return TimelineSegment(
        id: item.id,
        x: CGFloat(relativeStart) * totalWidth,
        width: max(CGFloat(relativeDuration) * totalWidth, 2),
        color: itemColor(item)
      )
    }
  }

  private func itemColor(_ item: TimelineItem) -> Color {
    switch item.category {
    case .snoring:
      return theme.intensityColor(item.intensity)
    case .sleepTalking:
      return theme.sleepTalkingColor
    case .noise, .coughing, .other:
      return theme.noiseColor
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

  private struct TimelineItem: Identifiable {
    let id: UUID
    let timestamp: Date
    let duration: TimeInterval
    let intensity: SnoreIntensity
    let category: SoundCategory
  }

  private struct TimelineSegment: Identifiable {
    let id: UUID
    let x: CGFloat
    let width: CGFloat
    let color: Color
  }
}
