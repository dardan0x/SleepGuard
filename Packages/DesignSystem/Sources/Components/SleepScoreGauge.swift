import SwiftUI

@MainActor
public struct SleepScoreGauge: View {
  let score: Int
  let theme: Theme
  let size: CGFloat

  public init(score: Int, theme: Theme, size: CGFloat = 160) {
    self.score = score
    self.theme = theme
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle()
        .stroke(theme.bgElevated, lineWidth: size * 0.08)

      Circle()
        .trim(from: 0, to: CGFloat(score) / 100.0)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [
              theme.scoreGreen,
              theme.scoreAmber,
              theme.scoreRed,
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
          ),
          style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.8), value: score)

      VStack(spacing: 2) {
        Text("\(score)")
          .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
          .foregroundStyle(theme.scoreColor(score))

        Text(Strings.statsMiniChartSleepScoreLabel)
          .font(.system(size: size * 0.11, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)
      }
    }
    .frame(width: size, height: size)
  }
}
