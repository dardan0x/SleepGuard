import Models
import SwiftUI

/// Expandable sleep-stage breakdown for a session: hypnogram chart + stage
/// legend, with an info button presenting `SleepStagesInfoView`.
@MainActor
public struct SleepStageBreakdownView: View {
  public let session: SleepSession
  public let theme: Theme
  @State private var isExpanded = true
  @State private var isInfoPresented = false

  public init(session: SleepSession, theme: Theme) {
    self.session = session
    self.theme = theme
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(Strings.statisticsSleepStagesLabel)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        Spacer()

        Button {
          isInfoPresented = true
        } label: {
          Image(systemName: "info.circle")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Strings.sleepStagesInfoTitle)

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
          }
        } label: {
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(isExpanded ? Strings.actionCollapse : Strings.actionExpand)
      }

      if isExpanded {
        SleepStageHypnogramChart(session: session, theme: theme)
          .padding(.horizontal, 30)
        SleepStageLegendGrid(session: session, theme: theme)
          .padding(.horizontal, 30)
      }
    }
    .sheet(isPresented: $isInfoPresented) {
      SleepStagesInfoView(session: session, theme: theme)
    }
  }
}
