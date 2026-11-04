import DesignSystem
import SwiftUI

/// Banner shown on the bedside clock when the Snore Interrupter is armed:
/// melody-enabled note + "Mute for session" action.
struct BedsideMelodyDisclaimer: View {
  @Environment(Theme.self) private var theme

  let onMute: () -> Void

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "music.note")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.accent)

      Text(Strings.sessionBedsideMelodyEnabled)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(theme.textSecondary)

      Text("·")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(theme.textTertiary)

      Button(action: onMute) {
        Text(Strings.muteForSession)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.accent)
      }
      .buttonStyle(.plain)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 15)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusSmall)
  }
}
