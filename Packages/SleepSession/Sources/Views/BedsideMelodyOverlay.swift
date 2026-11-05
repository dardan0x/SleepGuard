import DesignSystem
import FactoryKit
import SwiftUI

/// Top overlay on the bedside clock while the Snore Interrupter melody is
/// playing: melody name + mute/stop actions.
struct BedsideMelodyOverlay: View {
  @Injected(\.theme) private var theme

  let melodyName: String
  let onMute: () -> Void
  let onStop: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 12) {
        Image(systemName: "music.note")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.accent)
          .symbolEffect(.pulse, options: .repeating)

        Text("\(Strings.playingSnoreInterrupterPlayer) \(melodyName)")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(theme.textPrimary)
          .lineLimit(1)

        Spacer()
      }

      HStack(spacing: 12) {
        Button(action: onMute) {
          Text(Strings.muteForSession)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)

        Button(action: onStop) {
          Text(Strings.stopSnoreInterrupterPlayer)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .stroke(theme.accent, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(theme.bgCard)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(theme.accent.opacity(0.4), lineWidth: 1)
        )
    )
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
}
