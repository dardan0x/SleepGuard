import SwiftUI
import DesignSystem

struct BedsideClockWaveformView: View {
  let durationString: String
  let levels: [Double]
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Circle()
          .fill(theme.scoreGreen)
          .frame(width: 8, height: 8)
        Text("Recording · \(durationString)")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(theme.accent)
          .monospacedDigit()
      }

      AudioLevelMeter(
        levels: levels,
        theme: theme
      )
    }
  }
}
