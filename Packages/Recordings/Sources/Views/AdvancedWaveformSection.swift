import DesignSystem
import FactoryKit
import Models
import SwiftUI

/// Waveform section of the advanced player: tappable waveform shape plus
/// the seek hint.
struct AdvancedWaveformSection: View {
  @Injected(\.theme) private var theme

  let samples: [Float]
  let intensityColor: Color
  let onWaveformTap: (Double) -> Void

  var body: some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        WaveformShape(samples: samples)
          .fill(intensityColor.opacity(0.8))
          .frame(height: 80)
          .contentShape(Rectangle())
          .onTapGesture { location in
            let relative = Double(location.x / geometry.size.width)
            onWaveformTap(relative)
          }
      }
      .frame(height: 80)

      Text(Strings.recordingsPlayerSeekHint)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.textTertiary)
    }
  }
}
