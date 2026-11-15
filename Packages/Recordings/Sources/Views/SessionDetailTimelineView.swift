import DesignSystem
import Models
import SwiftUI

struct SessionDetailTimelineView: View {
  let session: SleepSession
  @State private var isSleepStagesExpanded = true

  var body: some View {
    VStack(alignment: .leading, spacing: 25) {
      if let stages = session.sleepStageSegments, !stages.isEmpty {
        SleepStageBreakdownView(session: session)
      }

      NightTimeline(session: session)
    }
  }
}
