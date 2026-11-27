import DesignSystem
import Models
import SleepStore
import SwiftUI

/// Expandable advanced player showing waveform, frequency spectrum, and spectral stats for a snore event clip.
struct SessionDetailAdvancedPlayerView: View {
  let event: NightEventRecord
  let waveformSamples: [Float]
  let spectrumBars: [Float]
  let onWaveformTap: (Double) -> Void
  @Environment(\.theme) private var theme
  var body: some View {
    VStack(spacing: 20) {
      AdvancedWaveformSection(
        samples: waveformSamples,
        intensityColor: theme.palette.eventColor(.snoring, intensity: event.intensity),
        onWaveformTap: onWaveformTap)
      AdvancedSpectrumSection(bars: spectrumBars)
      AdvancedStatsSection(event: event)
    }
    .padding(16)
    .background(theme.palette.bgCard)
    .cornerRadius(theme.radii.card)
  }
}
