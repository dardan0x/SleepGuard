import DesignSystem
import Models
import SwiftUI

/// Shown when an event has no playable audio: explanation plus the event's
/// time, duration and intensity for context.
struct NoAudioView: View {
  @Environment(Theme.self) private var theme

  let event: SnoreEvent

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 44))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.eventPlayerNoAudioTitle)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text(Strings.eventPlayerNoAudioDescription)
        .font(.system(size: 14))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 8) {
        Text(event.timestamp, style: .time)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textTertiary)
        Text("·")
          .foregroundStyle(theme.textTertiary)
        Text("\(Int(event.snoreDuration))s · \(event.intensity.rawValue.capitalized)")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}
