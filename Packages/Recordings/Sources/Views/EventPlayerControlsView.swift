import DesignSystem
import SwiftUI

/// Centered transport controls for the event player: skip back 15 s,
/// play/pause, skip forward 15 s.
struct EventPlayerControlsView: View {
  @Environment(Theme.self) private var theme

  let isPlaying: Bool
  let onTogglePlayback: () -> Void
  let onSkipBack: () -> Void
  let onSkipForward: () -> Void

  var body: some View {
    HStack(spacing: 40) {
      // Skip back 15s
      Button {
        onSkipBack()
      } label: {
        Image(systemName: "gobackward.15")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }

      // Play/Pause
      Button {
        onTogglePlayback()
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.bgPrimary)
          .frame(width: 72, height: 72)
          .background(Color.white)
          .clipShape(Circle())
      }

      // Skip forward 15s
      Button {
        onSkipForward()
      } label: {
        Image(systemName: "goforward.15")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
