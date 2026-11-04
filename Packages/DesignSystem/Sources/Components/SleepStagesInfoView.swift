import SwiftUI
import Models

/// Educational sheet explaining sleep stages: per-stage cards, the score
/// formula, and deep/REM/awake thresholds. Composes three section views.
@MainActor
public struct SleepStagesInfoView: View {
  public let session: SleepSession
  public let theme: Theme

  public init(session: SleepSession, theme: Theme? = nil) {
    self.session = session
    self.theme = theme ?? Theme.shared
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        SleepStagesInfoHeader()
        YourStagesSection(session: session, theme: theme)
        ScoreImpactSection(session: session, theme: theme)
      }
      .padding(20)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
  }
}
