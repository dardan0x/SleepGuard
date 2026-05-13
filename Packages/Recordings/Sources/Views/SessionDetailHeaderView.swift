import SwiftUI
import Models
import DesignSystem

struct SessionDetailHeaderView: View {
  let session: SleepSession
  let score: Int

  var body: some View {
    HStack(spacing: 16) {
      SleepScoreGauge(score: score, theme: theme, size: 120)

      SessionStatsGrid(session: session)
    }
  }

  @Environment(Theme.self) private var theme
}
