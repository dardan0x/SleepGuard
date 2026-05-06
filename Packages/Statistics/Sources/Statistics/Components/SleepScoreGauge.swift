import SwiftUI
import DesignSystem

@MainActor
public struct SleepScoreGauge: View {
  let score: Int
  let theme: Theme
  let size: CGFloat

  public init(score: Int, theme: Theme, size: CGFloat = 120) {
    self.score = score
    self.theme = theme
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle()
        .stroke(scoreColor.opacity(0.15), lineWidth: size * 0.1)

      Circle()
        .trim(from: 0, to: CGFloat(score) / 100.0)
        .stroke(scoreColor, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.8), value: score)

      VStack(spacing: 2) {
        Text("\(score)")
          .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
          .foregroundStyle(theme.labelColor)

        Text("Score")
          .font(.system(size: size * 0.13, weight: .medium))
          .foregroundStyle(theme.secondaryLabelColor)
      }
    }
    .frame(width: size, height: size)
  }

  private var scoreColor: Color {
    switch score {
    case 80...100:
      theme.secondaryColor
    case 50 ..< 80:
      Color.orange
    default:
      Color.red
    }
  }
}
