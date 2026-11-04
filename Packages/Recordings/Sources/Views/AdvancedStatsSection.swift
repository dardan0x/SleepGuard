import DesignSystem
import Models
import SwiftUI

/// Spectral stats grid of the advanced player: duration, dominant frequency,
/// spectral centroid, and low-frequency ratio.
struct AdvancedStatsSection: View {
  let event: SnoreEvent

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        StatBox(title: Strings.recordingsPlayerStatDuration, value: durationString(event.snoreDuration))
        StatBox(title: Strings.recordingsPlayerStatDominantFreq, value: frequencyString(event.dominantFrequency))
      }

      HStack(spacing: 12) {
        StatBox(title: Strings.recordingsPlayerStatSpectralCentroid, value: frequencyString(event.spectralCentroid))
        StatBox(title: Strings.recordingsPlayerStatLowFreqRatio, value: String(format: "%.0f%%", event.lowFreqRatio * 100))
      }
    }
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }

  private func frequencyString(_ hz: Double) -> String {
    if hz >= 1000 {
      return String(format: "%.1f kHz", hz / 1000)
    }
    return String(format: "%.0f Hz", hz)
  }
}
