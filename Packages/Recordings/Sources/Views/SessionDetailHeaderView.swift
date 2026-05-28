import SwiftUI
import Models
import DesignSystem

struct SessionDetailHeaderView: View {
  let session: SleepSession
  let score: Int

  @Environment(Theme.self) private var theme

  private var disturbanceCount: Int {
    session.events?.filter { $0.category != .snoring }.count ?? 0
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        SleepScoreGauge(score: score, theme: theme, size: 120)

        SessionStatsGrid(session: session)
      }

      if disturbanceCount > 0 {
        StatCard(
          icon: "speaker.wave.2.fill",
          title: Strings.sessionDisturbances,
          value: "\(disturbanceCount)",
          theme: theme,
          iconColor: theme.noiseColor
        )
      }
    }
  }
}
