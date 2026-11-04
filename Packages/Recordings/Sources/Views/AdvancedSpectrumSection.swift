import DesignSystem
import SwiftUI

/// Frequency-spectrum section of the advanced player: gradient-colored bars
/// plus frequency axis labels.
struct AdvancedSpectrumSection: View {
  @Environment(Theme.self) private var theme

  let bars: [Float]

  var body: some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<bars.count, id: \.self) { index in
            let height = max(CGFloat(bars[index]) * geometry.size.height, 2)
            RoundedRectangle(cornerRadius: 1)
              .fill(barColor(at: index, total: bars.count))
              .frame(height: height)
          }
        }
        .frame(height: 60)
      }
      .frame(height: 60)

      HStack {
        Text(Strings.recordingsPlayerFreq0)
        Spacer()
        Text(Strings.recordingsPlayerFreq500)
        Spacer()
        Text(Strings.recordingsPlayerFreq1k)
      }
      .font(.system(size: 9, weight: .medium))
      .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsPlayerSpectrumLabel)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.textTertiary)
    }
  }

  private func barColor(at index: Int, total: Int) -> Color {
    let ratio = Double(index) / Double(total - 1)
    if ratio < 0.33 {
      return theme.scoreGreen
    } else if ratio < 0.66 {
      return theme.scoreAmber
    } else {
      return theme.scoreRed
    }
  }
}
