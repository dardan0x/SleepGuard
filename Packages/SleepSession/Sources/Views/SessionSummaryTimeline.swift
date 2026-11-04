import DesignSystem
import Models
import SwiftUI

/// Snoring timeline with start/end time labels on the session summary.
struct SessionSummaryTimeline: View {
  @Environment(Theme.self) private var theme

  let session: SleepSession

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
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
