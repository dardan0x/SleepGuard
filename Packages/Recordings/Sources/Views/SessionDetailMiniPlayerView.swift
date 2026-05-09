import SwiftUI
import Models
import DesignSystem

struct SessionDetailMiniPlayerView: View {
  let session: SleepSession
  let isPlaying: Bool
  let progress: Double
  let totalDuration: TimeInterval
  let isExpandable: Bool
  let onTogglePlayback: () -> Void
  let onScrub: (Double) -> Void
  let onExpand: () -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        Button {
          onTogglePlayback()
        } label: {
          Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(theme.accent)
            .clipShape(Circle())
        }

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
              .fill(theme.bgElevated)
              .frame(height: 4)

            RoundedRectangle(cornerRadius: 2)
              .fill(theme.accent)
              .frame(width: max(CGFloat(progress) * geometry.size.width, 0), height: 4)

            // Event markers
            if let events = session.events?.sorted(by: { $0.timestamp < $1.timestamp }) {
              ForEach(events, id: \.id) { event in
                let eventProgress = session.totalDuration > 0
                  ? event.timestamp.timeIntervalSince(session.startDate) / session.totalDuration
                  : 0
                Circle()
                  .fill(theme.intensityColor(event.intensity))
                  .frame(width: 6, height: 6)
                  .position(
                    x: CGFloat(eventProgress) * geometry.size.width,
                    y: 2
                  )
              }
            }
          }
          .contentShape(Rectangle())
          .onTapGesture { location in
            let relative = Double(location.x / geometry.size.width)
            onScrub(relative)
          }
        }
        .frame(height: 4)

        Text(timeString(totalDuration))
          .font(.system(size: 11, weight: .medium, design: .monospaced))
          .foregroundStyle(theme.textTertiary)
          .monospacedDigit()

        if isExpandable {
          Button {
            onExpand()
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "waveform")
                .font(.system(size: 12, weight: .semibold))
              Text(Strings.recordingsDetailTitle)
                .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.accent.opacity(0.15))
            .cornerRadius(theme.radiusSmall)
          }
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusSmall)
  }

  private func timeString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }
}
