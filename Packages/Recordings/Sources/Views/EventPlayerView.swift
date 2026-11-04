import DesignSystem
import Models
import SwiftUI

/// Single-event audio player matching the SleepGuard design.
/// Shows event info, bar waveform with progress, and centered playback controls.
/// Composes `EventPlayerHeaderView`, `EventWaveformView`,
/// `EventPlayerControlsView` and `EventIntensityLegendView`.
@MainActor
struct EventPlayerView: View {
  let event: SnoreEvent
  let waveformSamples: [Float]
  let isPlaying: Bool
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let eventNumber: Int
  let totalEvents: Int
  let onTogglePlayback: () -> Void
  let onSkipBack: () -> Void
  let onSkipForward: () -> Void
  let onScrub: (Double) -> Void
  let isReady: Bool
  let isLoadingWaveform: Bool

  @Environment(Theme.self) private var theme

  private var intensityColor: Color {
    theme.intensityColor(event.intensity)
  }

  var body: some View {
    ZStack {
      VStack(spacing: 24) {
        EventPlayerHeaderView(
          event: event,
          eventNumber: eventNumber,
          totalEvents: totalEvents,
          totalDuration: totalDuration,
          intensityColor: intensityColor,
          intensityLabel: intensityLabel)
        EventWaveformView(
          event: event,
          intensityColor: intensityColor,
          waveformSamples: waveformSamples,
          currentTime: currentTime,
          totalDuration: totalDuration,
          isLoadingWaveform: isLoadingWaveform,
          onScrub: onScrub)
        EventPlayerControlsView(
          isPlaying: isPlaying,
          onTogglePlayback: onTogglePlayback,
          onSkipBack: onSkipBack,
          onSkipForward: onSkipForward)
        EventIntensityLegendView()
      }
      .padding(20)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)

      if !isReady {
        loadingOverlay
      }
    }
  }

  private var loadingOverlay: some View {
    VStack(spacing: 12) {
      ProgressView()
        .scaleEffect(1.2)
        .tint(theme.accent)
      Text(Strings.loadingAudioEventPlayerView)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(theme.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.bgCard.opacity(0.95))
    .cornerRadius(theme.radiusCard)
  }

  private var intensityLabel: String {
    switch event.intensity {
    case .quiet: Strings.quietIntensityLabel
    case .light: Strings.lightIntensityLabelEventPlayerView
    case .loud: Strings.loudIntensityLabelEventPlayerView
    case .epic: Strings.epicIntensityLabelEventPlayerView
    }
  }
}
