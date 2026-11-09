import DesignSystem
import Models
import SwiftUI

struct LastNightMediumView: View {
  let night: WidgetSnapshot.Night
  let theme = Theme.shared

  var body: some View {
    HStack(spacing: 20) {
      SleepScoreGauge(score: night.score, theme: theme, size: 116)

      VStack(alignment: .leading, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          LastNightLabel()
          Text(night.startDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.textPrimary)
        }

        LastNightStatRow(title: Strings.widgetLastNightSlept, value: night.sleptText)
        LastNightStatRow(title: Strings.widgetLastNightSnoring, value: night.snoringText)
      }

      Spacer(minLength: 0)
    }
  }
}

struct LastNightStatRow: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(title)
        .font(.caption)
        .foregroundStyle(Theme.shared.textTertiary)
      Text(value)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Theme.shared.textPrimary)
    }
  }
}
