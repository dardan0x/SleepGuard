import DesignSystem
import Models
import SwiftUI

struct LastNightMediumView: View {
  let night: WidgetSnapshot.Night
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 20) {
      SleepScoreGauge(score: night.score, size: 116)

      VStack(alignment: .leading, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          LastNightLabel()
          Text(night.startDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.palette.textPrimary)
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
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(title)
        .font(.caption)
        .foregroundStyle(theme.palette.textTertiary)
      Text(value)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.palette.textPrimary)
    }
  }
}
