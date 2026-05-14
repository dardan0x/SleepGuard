import SwiftUI

@MainActor
public struct SleepScoreGauge: View {
  let score: Int
  let theme: Theme
  let size: CGFloat

  @State private var animatedProgress: CGFloat = 0

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
        .trim(from: 0, to: animatedProgress)
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
        .animation(.easeOut(duration: 0.8), value: animatedProgress)

      VStack(spacing: 2) {
        Text("\(score)")
          .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
          .foregroundStyle(theme.scoreColor(score))

        Text(Strings.statsMiniChartSleepScoreLabel)
          .font(.system(size: size * 0.09, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)
      }
    }
    .frame(width: size, height: size)
    .onAppear {
      animatedProgress = CGFloat(score) / 100.0
    }
    .onChange(of: score) { _, newScore in
      animatedProgress = CGFloat(newScore) / 100.0
    }
  }
}
