import SwiftUI
import Models
import DesignSystem

@MainActor
struct HiddenEventsSection: View {
  let events: [SnoreEvent]
  let displayDurations: [UUID: TimeInterval]?
  let onPlayEvent: (SnoreEvent) -> Void
  let onShareEvent: (SnoreEvent) -> Void
  @Environment(Theme.self) private var theme

  @State private var isExpanded: Bool = false

  var body: some View {
    VStack(spacing: 8) {
      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          isExpanded.toggle()
        }
      } label: {
        HStack(spacing: 8) {
          Text(String(format: Strings.sessionDetailHiddenEventsFormat, events.count))
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)

          Spacer()

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusCard)
      }

      if isExpanded {
        VStack(spacing: 6) {
          ForEach(events, id: \.id) { event in
            EventRow(
              event: event,
              displayDuration: displayDurations?[event.id],
              theme: theme,
              onPlay: { onPlayEvent(event) },
              onShare: { onShareEvent(event) }
            )
          }
        }
      }
    }
  }
}
