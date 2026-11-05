import DesignSystem
import FactoryKit
import Models
import SwiftUI

/// Four-intensity legend so users can read what dot/text color means anywhere
/// in the app. Pulls colors via `theme.intensityColor(_:)` — the same source
/// the burst-dots and header use — so the legend never drifts out of sync.
struct EventIntensityLegendView: View {
  @Injected(\.theme) private var theme

  var body: some View {
    HStack(spacing: 14) {
      legendItem(intensity: .quiet, label: Strings.quietIntensityLabel)
      legendItem(intensity: .light, label: Strings.lightIntensityLabelEventPlayerView)
      legendItem(intensity: .loud, label: Strings.loudIntensityLabelEventPlayerView)
      legendItem(intensity: .epic, label: Strings.epicIntensityLabelEventPlayerView)
    }
  }

  private func legendItem(intensity: SnoreIntensity, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(theme.intensityColor(intensity))
        .frame(width: 8, height: 8)
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(theme.textSecondary)
    }
  }
}
