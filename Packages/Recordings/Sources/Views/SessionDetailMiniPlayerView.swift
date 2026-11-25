import DesignSystem
import Models
import SwiftUI

struct SessionDetailMiniPlayerView: View {
  let session: SleepSession
  let isPlaying: Bool
  let progress: Double
  let totalDuration: TimeInterval
  let eventMarkers: [Double]
  let eventMarkerColors: [Color]
  let isExpandable: Bool
  let showsPlaybackButton: Bool
  let onTogglePlayback: () -> Void
  let onScrub: (Double) -> Void
  let onExpand: () -> Void
  @Environment(\.theme) private var theme
  init(
    session: SleepSession,
    isPlaying: Bool,
    progress: Double,
    totalDuration: TimeInterval,
    eventMarkers: [Double],
    eventMarkerColors: [Color],
    isExpandable: Bool,
    showsPlaybackButton: Bool = true,
    onTogglePlayback: @escaping () -> Void,
    onScrub: @escaping (Double) -> Void,
    onExpand: @escaping () -> Void)
  {
    self.session = session
    self.isPlaying = isPlaying
    self.progress = progress
    self.totalDuration = totalDuration
    self.eventMarkers = eventMarkers
    self.eventMarkerColors = eventMarkerColors
    self.isExpandable = isExpandable
    self.showsPlaybackButton = showsPlaybackButton
    self.onTogglePlayback = onTogglePlayback
    self.onScrub = onScrub
    self.onExpand = onExpand
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        if showsPlaybackButton {
          Button {
            onTogglePlayback()
          } label: {
            Label(isPlaying ? Strings.a11yPause : Strings.actionPlay, systemImage: isPlaying ? "pause.fill" : "play.fill").labelStyle(.iconOnly)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.white)
              .frame(width: 28, height: 28)
              .background(theme.palette.accent)
              .clipShape(Circle())
          }
        }

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
              .fill(theme.palette.bgElevated)
              .frame(height: 4)

            RoundedRectangle(cornerRadius: 2)
              .fill(theme.palette.accent)
              .frame(width: max(CGFloat(progress) * geometry.size.width, 0), height: 4)

            // Event markers — positions are pre-computed to match the same timeline
            // as the progress bar (clips timeline for clip sessions, session timeline
            // for legacy full-session playback).
            ForEach(eventMarkers.indices, id: \.self) { index in
              Circle()
                .fill(eventMarkerColors.indices.contains(index) ? eventMarkerColors[index] : theme.palette.accent)
                .frame(width: 6, height: 6)
                .position(
                  x: CGFloat(eventMarkers[index]) * geometry.size.width,
                  y: 2)
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
          .foregroundStyle(theme.palette.textTertiary)
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
            .foregroundStyle(theme.palette.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.palette.accent.opacity(0.15))
            .cornerRadius(theme.radii.small)
          }
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .background(theme.palette.bgCard)
    .cornerRadius(theme.radii.small)
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
