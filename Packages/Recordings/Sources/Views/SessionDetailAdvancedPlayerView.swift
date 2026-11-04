import DesignSystem
import Models
import SwiftUI

/// Expandable advanced player showing waveform, frequency spectrum, and spectral stats for a snore event clip.
struct SessionDetailAdvancedPlayerView: View {
  let event: SnoreEvent
  let waveformSamples: [Float]
  let spectrumBars: [Float]
  let onWaveformTap: (Double) -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 20) {
      AdvancedWaveformSection(
        samples: waveformSamples,
        intensityColor: theme.intensityColor(event.intensity),
        onWaveformTap: onWaveformTap)
      AdvancedSpectrumSection(bars: spectrumBars)
      AdvancedStatsSection(event: event)
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}
