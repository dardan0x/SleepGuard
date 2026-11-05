import DesignSystem
import FactoryKit
import Models
import SwiftUI

/// "Events" section below the player: every snore event of the session as
/// tappable rows with the active event highlighted.
struct PlayerEventListSection: View {
  @Injected(\.theme) private var theme

  let events: [SnoreEvent]
  let currentEventIndex: Int
  let isPlaying: Bool
  let onSelect: (Int) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.recordingsDetailEventsLabel)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      VStack(spacing: 6) {
        ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
          PlayerEventRow(
            event: event,
            isActive: currentEventIndex == index,
            isPlaying: isPlaying,
            onTap: { onSelect(index) })
        }
      }
    }
  }
}
