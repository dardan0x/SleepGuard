import DesignSystem
import Models
import SwiftUI

struct StatisticsStatsGrid: View {
  let session: SleepSession

  var body: some View {
    SessionStatsGrid(session: session)
  }
}
