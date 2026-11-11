import FactoryKit
import Models
import SwiftUI

/// Two-column legend under the hypnogram: stage color chip + duration for
/// each of the four stages.
struct SleepStageLegendGrid: View {
  let session: SleepSession
  @Injected(\.theme) private var theme

  var body: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    return LazyVGrid(columns: columns, spacing: 10) {
      legendItem(stage: .awake, name: Strings.sleepStageAwake)
      legendItem(stage: .light, name: Strings.sleepStageLightSleep)
      legendItem(stage: .rem, name: Strings.sleepStageRem)
      legendItem(stage: .deep, name: Strings.sleepStageDeepSleep)
    }
  }

  private func legendItem(stage: SleepStage, name: String) -> some View {
    HStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 4)
        .fill(theme.stageColor(stage))
        .frame(width: 12, height: 12)

      Text("\(name): \(durationString(for: stage))")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textSecondary)
    }
  }

  private func durationString(for stage: SleepStage) -> String {
    let minutes = Int(totalDuration(for: stage) / 60)
    return DurationFormatter.hoursAndMinutes(minutes)
  }

  private func totalDuration(for stage: SleepStage) -> TimeInterval {
    session.sleepStageSegments?
      .filter { $0.stage == stage }
      .reduce(0) { $0 + $1.duration } ?? 0
  }
}
