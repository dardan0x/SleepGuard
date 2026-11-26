import Config
import DesignSystem
import FactoryKit
import Models
import SwiftUI

/// The dashboard: SleepGuard's title and calendar button, the shared content
/// (`StatisticsDashboardContent`, ADR 0006) with the night's sleep stages in
/// its slot, and Start Recording.
@MainActor
struct StatisticsLoadedView: View {
  let state: DashboardState
  @Environment(\.theme) private var theme
  @Injected(\.appConfig) private var appConfig
  @MainActor let onStartRecording: () -> Void
  let onViewTrends: () -> Void
  let onViewCalendar: () -> Void
  let onViewLastSevenNights: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      StatisticsLoadedHeaderView(onViewCalendar: onViewCalendar)
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        // The latest night in full (events read): the dashboard itself is built
        // from summaries without events.
        StatisticsDashboardContent(
          dashboard: state.dashboard, latest: state.session.summary, now: state.now,
          compact: DeviceSize.isCompactHeight, onShowTrends: onViewTrends, onShowLastSevenNights: onViewLastSevenNights)
        {
          SleepStagesSection(session: state.session, scoreConfig: appConfig.sleepScoreConfig)
        }
      }

      StartRecordingButton(height: 56) {
        onStartRecording()
      }
      .padding(.horizontal, 20)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea(edges: .bottom))
    .toolbar(.hidden, for: .navigationBar)
  }
}
