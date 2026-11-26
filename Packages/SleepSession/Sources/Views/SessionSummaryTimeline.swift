import DesignSystem
import Models
import SwiftUI

/// Snoring timeline with start/end time labels on the session summary.
struct SessionSummaryTimeline: View {
  let session: NightRecord

  var body: some View {
    NightTimeline(session: session, showsTitle: false)
  }
}
