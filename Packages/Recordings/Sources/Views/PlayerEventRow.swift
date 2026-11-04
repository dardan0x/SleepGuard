import DesignSystem
import Models
import SwiftUI

/// Row in the event list below the player: category indicator, time range,
/// duration and intensity. Highlights when it is the active event.
struct PlayerEventRow: View {
  @Environment(Theme.self) private var theme

  let event: SnoreEvent
  let isActive: Bool
  let isPlaying: Bool
  let onTap: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      categoryIndicator

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(DateFormatters.timeWithPeriod.string(from: event.timestamp))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? theme.accent : theme.textPrimary)

          Text("–")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)

          Text(DateFormatters.timeWithPeriod.string(from: endTime))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? theme.accent : theme.textPrimary)
        }

        Text("\(Int(event.snoreDuration))s · \(event.intensity.rawValue.capitalized)")
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
      }

      Spacer()

      if isActive && isPlaying {
        Image(systemName: "waveform")
          .font(.system(size: 14))
          .foregroundStyle(theme.accent)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(isActive ? theme.accent.opacity(0.10) : theme.bgCard)
    .cornerRadius(theme.radiusCard)
    .contentShape(Rectangle())
    .onTapGesture(perform: onTap)
  }

  private var endTime: Date {
    event.timestamp.addingTimeInterval(event.snoreDuration)
  }

  @ViewBuilder
  private var categoryIndicator: some View {
    switch event.category {
    case .snoring:
      Circle()
        .fill(theme.intensityColor(event.intensity))
        .frame(width: 8, height: 8)
    case .sleepTalking:
      Image(systemName: "bubble.left.fill")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(theme.sleepTalkingColor)
        .frame(width: 10, height: 10)
    case .noise, .coughing, .other:
      Image(systemName: "waveform")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(theme.noiseColor)
        .frame(width: 10, height: 10)
    }
  }
}
