import DesignSystem
import Models
import SwiftUI

struct LastNightSmallView: View {
  let night: WidgetSnapshot.Night
  @Environment(\.theme) private var theme
  var body: some View {
    VStack(spacing: 6) {
      LastNightLabel()

      SleepScoreGauge(score: night.score, size: 84)

      Text(night.sleptText)
        .font(.caption.weight(.medium))
        .foregroundStyle(theme.palette.textSecondary)
    }
  }
}
