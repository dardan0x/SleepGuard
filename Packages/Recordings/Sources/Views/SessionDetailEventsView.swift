import DesignSystem
import FactoryKit
import Models
import SwiftUI

struct SessionDetailEventsView: View {
  let events: [SnoreEvent]
  let displayDurations: [UUID: TimeInterval]?
  let title: String
  let onShowAll: () -> Void
  let onPlayEvent: (SnoreEvent) -> Void
  let onShareEvent: (SnoreEvent) -> Void
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(String(format: title, events.count))
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      VStack(spacing: 8) {
        ForEach(Array(events.prefix(4)), id: \.id) { event in
          EventRow(
            event: event,
            displayDuration: displayDurations?[event.id],
            theme: theme,
            onPlay: { onPlayEvent(event) },
            onShare: { onShareEvent(event) })
        }
      }

      if events.count > 4 {
        Button {
          onShowAll()
        } label: {
          Text(String(format: Strings.recordingsDetailShowAllFormat, events.count))
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 10)
      }
    }
  }
}
