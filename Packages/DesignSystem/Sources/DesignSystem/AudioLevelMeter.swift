import SwiftUI

@MainActor
public struct AudioLevelMeter: View {
  let levels: [Double]
  let theme: Theme

  public init(levels: [Double], theme: Theme) {
    self.levels = levels
    self.theme = theme
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 6) {
      ForEach(0..<levels.count, id: \.self) { index in
        RoundedRectangle(cornerRadius: 3)
          .fill(barColor(for: levels[index]))
          .frame(width: 8, height: barHeight(for: levels[index]))
      }
    }
    .frame(height: 80)
  }

  private func barHeight(for level: Double) -> CGFloat {
    CGFloat(level) * 80
  }

  private func barColor(for level: Double) -> Color {
    if level > 0.7 {
      return theme.snoreLoud
    } else if level > 0.4 {
      return theme.snoreLight
    } else {
      return theme.snoreQuiet
    }
  }
}
