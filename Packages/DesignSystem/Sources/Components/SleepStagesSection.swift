import Models
import SleepCore
import SwiftUI

/// The night's sleep stages (the shared `SleepStagesCard`) with its info
/// sheet (`SleepStagesInfoContent`), from the stored session. Shows nothing
/// when the session has no stage time. `scoreConfig` is the score's, so the
/// sheet's targets and penalty are the ones applied.
@MainActor
public struct SleepStagesSection: View {
  let session: SleepSession
  let scoreConfig: SleepScoreConfig
  @State private var isInfoPresented = false

  public init(session: SleepSession, scoreConfig: SleepScoreConfig) {
    self.session = session
    self.scoreConfig = scoreConfig
  }

  public var body: some View {
    if let breakdown = SleepStageBreakdown(segments: session.sleepStageSegments ?? []) {
      SleepStagesCard(breakdown: breakdown, start: session.startDate, duration: session.totalDuration) {
        isInfoPresented = true
      }
      .sheet(isPresented: $isInfoPresented) {
        SleepStagesInfoContent(breakdown: breakdown, config: scoreConfig) { isInfoPresented = false }
      }
    }
  }
}
