public import Models
public import SleepCore
public import SwiftUI

/// The night's sleep stages (the shared `SleepStagesCard`) with its info
/// sheet (`SleepStagesInfoContent`), from the stored session. Shows nothing
/// when the session has no stage time. `scoreConfig` is the score's, so the
/// sheet's targets and penalty are the ones applied.
@MainActor
public struct SleepStagesSection: View {
  let session: NightRecord
  let scoreConfig: SleepScoreConfig
  @State private var isInfoPresented = false

  public init(session: NightRecord, scoreConfig: SleepScoreConfig) {
    self.session = session
    self.scoreConfig = scoreConfig
  }

  public var body: some View {
    if let breakdown = SleepStageBreakdown(segments: session.sleepStages) {
      SleepStagesCard(breakdown: breakdown, start: session.start, duration: session.totalDuration) {
        isInfoPresented = true
      }
      .sheet(isPresented: $isInfoPresented) {
        SleepStagesInfoContent(breakdown: breakdown, config: scoreConfig) { isInfoPresented = false }
      }
    }
  }
}
