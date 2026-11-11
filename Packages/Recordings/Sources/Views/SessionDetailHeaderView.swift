import DesignSystem
import FactoryKit
import Models
import SwiftUI

struct SessionDetailHeaderView: View {
  let session: SleepSession
  let score: Int

  @Injected(\.theme) private var theme

  private var disturbanceCount: Int {
    session.events?.filter { $0.category != .snoring }.count ?? 0
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        SleepScoreGauge(score: score, size: 120)

        SessionStatsGrid(session: session)
      }

      if disturbanceCount > 0 {
        StatCard(
          icon: "speaker.wave.2.fill",
          title: Strings.sessionDisturbances,
          value: "\(disturbanceCount)",
          iconColor: theme.noiseColor)
      }
    }
  }
}
