import FactoryKit
import Models
import SwiftUI

/// "Your Stages" section of the sleep-stages info sheet: one card per stage
/// with duration, percentage, status badge, recommendation, and description.
struct YourStagesSection: View {
  let session: SleepSession
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Strings.sleepStagesInfoYourStages)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      VStack(spacing: 12) {
        stageCard(.awake)
        stageCard(.rem)
        stageCard(.light)
        stageCard(.deep)
      }
    }
  }

  private enum StageStatus {
    case good
    case low
    case high
  }

  private func stageCard(_ stage: SleepStage) -> some View {
    let duration = totalDuration(for: stage)
    let pct = percentage(for: stage)
    let status = status(for: stage, pct: pct)

    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 4)
          .fill(theme.stageColor(stage))
          .frame(width: 12, height: 12)

        Text(stageName(stage))
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(theme.textPrimary)

        Spacer()

        Text(statusLabel(status))
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(statusColor(status))
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(statusColor(status).opacity(0.15))
          .cornerRadius(8)
      }

      Text(String(format: "%.0f%% · %@", pct, durationString(duration)))
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textSecondary)

      if status != .good {
        Text(recommendedLabel(stage))
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }

      Text(stageDescription(stage))
        .font(.system(size: 13))
        .foregroundStyle(theme.textTertiary)
        .lineLimit(2)
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(12)
  }

  private func totalDuration(for stage: SleepStage) -> TimeInterval {
    session.sleepStageSegments?
      .filter { $0.stage == stage }
      .reduce(0) { $0 + $1.duration } ?? 0
  }

  private func percentage(for stage: SleepStage) -> Double {
    guard let stats = session.stageStats else { return 0 }
    switch stage {
    case .awake: return stats.awakePct
    case .rem: return stats.remPct
    case .light: return stats.lightPct
    case .deep: return stats.deepPct
    }
  }

  private func status(for stage: SleepStage, pct: Double) -> StageStatus {
    switch stage {
    case .deep:
      return pct >= 15 ? .good : .low
    case .rem:
      return pct >= 18 ? .good : .low
    case .awake:
      return pct <= 8 ? .good : .high
    case .light:
      if pct > 60 { return .high }
      if pct < 40 { return .low }
      return .good
    }
  }

  private func statusLabel(_ status: StageStatus) -> String {
    switch status {
    case .good: Strings.sleepStagesInfoStageStatusGood
    case .low: Strings.sleepStagesInfoStageStatusLow
    case .high: Strings.sleepStagesInfoStageStatusHigh
    }
  }

  private func statusColor(_ status: StageStatus) -> Color {
    switch status {
    case .good: theme.scoreGreen
    case .low: theme.scoreAmber
    case .high: theme.scoreRed
    }
  }

  private func stageName(_ stage: SleepStage) -> String {
    switch stage {
    case .awake: Strings.sleepStageAwake
    case .rem: Strings.sleepStageRem
    case .light: Strings.sleepStageLightSleep
    case .deep: Strings.sleepStageDeepSleep
    }
  }

  private func stageDescription(_ stage: SleepStage) -> String {
    switch stage {
    case .awake: Strings.sleepStagesInfoAwakeDescription
    case .rem: Strings.sleepStagesInfoRemDescription
    case .light: Strings.sleepStagesInfoLightDescription
    case .deep: Strings.sleepStagesInfoDeepDescription
    }
  }

  private func recommendedLabel(_ stage: SleepStage) -> String {
    let recommendation: String = switch stage {
    case .awake: Strings.sleepStagesInfoRecommendedAwake
    case .rem: Strings.sleepStagesInfoRecommendedRem
    case .light: Strings.sleepStagesInfoRecommendedLight
    case .deep: Strings.sleepStagesInfoRecommendedDeep
    }
    return String(format: Strings.sleepStagesInfoRecommended, recommendation)
  }

  private func durationString(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    return DurationFormatter.hoursAndMinutes(minutes)
  }
}
