import DesignSystem
import Models
import SwiftUI

struct LastNightSmallView: View {
  let night: WidgetSnapshot.Night
  let theme = Theme.shared

  var body: some View {
    VStack(spacing: 6) {
      LastNightLabel()

      SleepScoreGauge(score: night.score, theme: theme, size: 84)

      Text(night.sleptText)
        .font(.caption.weight(.medium))
        .foregroundStyle(theme.textSecondary)
    }
  }
}
