import FactoryKit
import Models
import SwiftUI

/// Educational sheet explaining sleep stages: per-stage cards, the score
/// formula, and deep/REM/awake thresholds. Composes three section views.
@MainActor
public struct SleepStagesInfoView: View {
  public let session: SleepSession
  @Injected(\.theme) private var theme

  public init(session: SleepSession, theme: (any ThemeProviding)? = nil) {
    self.session = session
    self.theme = theme ?? Container.shared.theme()
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        SleepStagesInfoHeader()
        YourStagesSection(session: session)
        ScoreImpactSection(session: session)
      }
      .padding(20)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
  }
}
