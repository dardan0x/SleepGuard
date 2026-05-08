import SwiftUI
import Models
import DesignSystem

struct SessionDetailTimelineView: View {
  let session: SleepSession
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("SNORING TIMELINE")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      SnoringTimelineView(session: session, theme: theme)

      HStack {
        Text(timeString(session.startDate))
          .font(.caption2)
          .foregroundStyle(theme.textTertiary)

        Spacer()

        if let endDate = session.endDate {
          Text(timeString(endDate))
            .font(.caption2)
            .foregroundStyle(theme.textTertiary)
        }
      }
    }
  }

  private func timeString(_ date: Date) -> String {
    DateFormatters.timeWithPeriod.string(from: date)
  }
}
