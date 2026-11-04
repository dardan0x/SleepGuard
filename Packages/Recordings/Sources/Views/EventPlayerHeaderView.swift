import DesignSystem
import Models
import SwiftUI

/// Event player header: event time, "SNORING EVENT" eyebrow, duration ·
/// intensity, and the event counter for multi-event playback.
struct EventPlayerHeaderView: View {
  @Environment(Theme.self) private var theme

  let event: SnoreEvent
  let eventNumber: Int
  let totalEvents: Int
  let totalDuration: TimeInterval
  let intensityColor: Color
  let intensityLabel: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(eventTimeString)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textSecondary)

      Text(Strings.snoringEventHeaderPlayerView.uppercased())
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1.5)

      HStack(spacing: 8) {
        Text(durationString(totalDuration))
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(theme.textPrimary)

        Text("·")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.textSecondary)

        Text(intensityLabel)
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(intensityColor)
      }

      if totalEvents > 1 {
        Text("\(Strings.eventHeaderSectionTotalEvents) \(eventNumber) of \(totalEvents)")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var eventTimeString: String {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: event.timestamp)
    let minute = calendar.component(.minute, from: event.timestamp)
    let period = hour >= 12 ? "pm" : "am"
    let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
    return String(format: "%d:%02d %@", displayHour, minute, period)
  }

  private func durationString(_ total: TimeInterval) -> String {
    let minutes = Int(total) / 60
    let seconds = Int(total) % 60
    if minutes > 0 {
      return "\(minutes)m \(seconds)s"
    }
    return "\(seconds)s"
  }
}
