import SwiftUI
import Models
import DesignSystem

struct StatisticsStatsGrid: View {
  let session: SleepSession

  var body: some View {
    SessionStatsGrid(session: session)
  }
}
