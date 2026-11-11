import DesignSystem
import FactoryKit
import SwiftUI

/// Centered transport controls for the event player: skip back 15 s,
/// play/pause, skip forward 15 s.
struct EventPlayerControlsView: View {
  @Injected(\.theme) private var theme

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
        Label(Strings.a11ySkipBack15, systemImage: "gobackward.15").labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }

      // Play/Pause
      Button {
        onTogglePlayback()
      } label: {
        Label(isPlaying ? Strings.a11yPause : Strings.actionPlay, systemImage: isPlaying ? "pause.fill" : "play.fill").labelStyle(.iconOnly)
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
        Label(Strings.a11ySkipForward15, systemImage: "goforward.15").labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
