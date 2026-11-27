import DesignSystem
import SleepStrings
import SwiftUI

/// "N short events": opens the player on the snoring episodes too short for
/// the list. SleepGuard only; sits in the shared detail content's footer slot.
struct ShortEventsButton: View {
  let count: Int
  let action: () -> Void
  @Environment(\.theme) private var theme
  var body: some View {
    if count > 0 {
      Button(action: action) {
        HStack(spacing: 8) {
          Image(systemName: "waveform")
            .font(.system(size: 14, weight: .semibold))
          Text(String(format: Strings.sessionDetailHiddenEventsFormat, count))
            .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(theme.palette.accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.palette.accent.opacity(0.12))
        .cornerRadius(theme.radii.card)
      }
    }
  }
}
