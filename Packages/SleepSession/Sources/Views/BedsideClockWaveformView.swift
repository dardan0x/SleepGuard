import DesignSystem
import FactoryKit
import SwiftUI

struct BedsideClockWaveformView: View {
  let durationString: String
  let levels: [Double]
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Circle()
          .fill(theme.scoreGreen)
          .frame(width: 8, height: 8)
        Text(String(format: Strings.sessionRecordingStatusFormat, durationString))
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(theme.accent)
          .monospacedDigit()
      }

      AudioLevelMeter(
        levels: levels,
        theme: theme)
    }
  }
}
