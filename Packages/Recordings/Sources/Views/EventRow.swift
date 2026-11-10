import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct EventRow: View {
  let event: SnoreEvent
  let displayDuration: TimeInterval?
  let theme: any ThemeProviding
  let onPlay: () -> Void
  let onShare: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 12) {
        categoryIndicator

        Text(timeString(event.timestamp))
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(theme.textPrimary)
          .monospacedDigit()

        Text(durationString(displayDuration ?? event.snoreDuration))
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .monospacedDigit()

        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture {
        onPlay()
      }

      HStack(spacing: 12) {
        Button {
          onShare()
        } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 14))
            .foregroundStyle(theme.textTertiary)
        }

        Button {
          onPlay()
        } label: {
          Image(systemName: "play.fill")
            .font(.system(size: 14))
            .foregroundStyle(theme.accent)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  @ViewBuilder
  private var categoryIndicator: some View {
    switch event.category {
    case .snoring:
      Circle()
        .fill(theme.intensityColor(event.intensity))
        .frame(width: 10, height: 10)
    case .sleepTalking:
      Image(systemName: "bubble.left.fill")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.sleepTalkingColor)
        .frame(width: 12, height: 12)
    case .noise, .coughing, .other:
      Image(systemName: "waveform")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.noiseColor)
        .frame(width: 12, height: 12)
    }
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    return formatter.string(from: date)
  }

  private func durationString(_ total: TimeInterval) -> String {
    let minutes = Int(total) / 60
    let seconds = Int(total) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}
