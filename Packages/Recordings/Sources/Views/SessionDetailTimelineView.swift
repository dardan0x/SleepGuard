import DesignSystem
import FactoryKit
import Models
import SwiftUI

struct SessionDetailTimelineView: View {
  let session: SleepSession
  @Injected(\.theme) private var theme
  @State private var isSleepStagesExpanded = true

  var body: some View {
    VStack(alignment: .leading, spacing: 25) {
      if let stages = session.sleepStageSegments, !stages.isEmpty {
        SleepStageBreakdownView(session: session)
      }

      VStack(alignment: .leading) {
        Text(Strings.recordingsDetailTimelineLabel)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        SnoringTimelineView(session: session)

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
  }

  private func timeString(_ date: Date) -> String {
    DateFormatters.timeWithPeriod.string(from: date)
  }
}
