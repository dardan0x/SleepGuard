import SwiftUI
import Models
import DesignSystem

struct SessionDetailEventsView: View {
  let session: SleepSession
  let showAllEvents: Bool
  let onToggleShowAll: () -> Void
  let onPlayEvent: (SnoreEvent) -> Void
  let onShareEvent: (SnoreEvent) -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    let events = session.events?.sorted { $0.timestamp < $1.timestamp } ?? []

    VStack(alignment: .leading, spacing: 16) {
      Text("EVENTS · \(events.count)")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      VStack(spacing: 8) {
        ForEach(showAllEvents ? events : Array(events.prefix(4)), id: \.id) { event in
          EventRow(
            event: event,
            theme: theme,
            onPlay: { onPlayEvent(event) },
            onShare: { onShareEvent(event) }
          )
        }
      }

      if events.count > 4 {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            onToggleShowAll()
          }
        } label: {
          Text(showAllEvents ? "Show less" : "Show all \(events.count)")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
    }
  }
}
