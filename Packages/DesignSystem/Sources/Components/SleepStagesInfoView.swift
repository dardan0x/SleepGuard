import Models
import SwiftUI

@MainActor
public struct SleepStagesInfoView: View {
  public let session: SleepSession
  public let theme: Theme
  @Environment(Theme.self) private var envTheme
  @Environment(\.dismiss) private var dismiss

  public init(session: SleepSession, theme: Theme? = nil) {
    self.session = session
    self.theme = theme ?? Theme.shared
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerBar
        yourStagesSection
        scoreImpactSection
      }
      .padding(20)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
  }

  // MARK: - Header

  private var headerBar: some View {
    HStack {
      Text(Strings.sleepStagesInfoTitle)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 22))
          .foregroundStyle(theme.textTertiary)
      }
      .accessibilityLabel(Strings.actionClose)
    }
  }

  // MARK: - Your Stages

  private var yourStagesSection: some View {
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

  // MARK: - Score Impact

  private var scoreImpactSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Strings.sleepStagesInfoScoreImpact)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      VStack(alignment: .leading, spacing: 12) {
        Text(Strings.sleepStagesInfoScoreFormula)
          .font(.system(size: 13))
          .foregroundStyle(theme.textSecondary)
          .lineSpacing(4)

        if let stats = session.stageStats {
          let penalty = computedStagePenalty(stats: stats)
          if penalty > 0 {
            Text(String(format: Strings.sleepStagesInfoPenaltyFormat, penalty))
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(theme.scoreAmber)
          } else {
            Text(Strings.sleepStagesInfoNoPenalty)
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(theme.scoreGreen)
          }

          VStack(spacing: 10) {
            thresholdBar(
              label: Strings.sleepStageDeepSleep,
              value: stats.deepPct,
              target: 15,
              mode: .minimum,
              color: theme.stageDeepColor)
            thresholdBar(
              label: Strings.sleepStageRem,
              value: stats.remPct,
              target: 18,
              mode: .minimum,
              color: theme.stageREMColor)
            thresholdBar(
              label: Strings.sleepStageAwake,
              value: stats.awakePct,
              target: 8,
              mode: .maximum,
              color: theme.stageAwakeColor)
          }
          .padding(.top, 4)
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  private func thresholdBar(
    label: String,
    value: Double,
    target: Double,
    mode: ThresholdMode,
    color: Color) -> some View
  {
    let isGood = mode == .minimum ? value >= target : value <= target

    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textSecondary)
        Spacer()
        Text(String(format: "%.0f%%", value))
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(isGood ? theme.scoreGreen : theme.scoreAmber)
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 3)
            .fill(theme.border)
            .frame(height: 6)

          let maxDisplay = mode == .minimum ? max(value, target) * 1.2 : max(value, target) * 1.5
          let clampedValue = max(0, min(value, maxDisplay))
          let valueWidth = maxDisplay > 0 ? (clampedValue / maxDisplay) * geo.size.width : 0
          let targetWidth = maxDisplay > 0 ? (target / maxDisplay) * geo.size.width : 0

          RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: valueWidth, height: 6)

          Circle()
            .fill(theme.textPrimary)
            .frame(width: 6, height: 6)
            .offset(x: targetWidth - 3)
        }
      }
      .frame(height: 6)
    }
  }

  // MARK: - Helpers

  private enum ThresholdMode {
    case minimum
    case maximum
  }

  private enum StageStatus {
    case good
    case low
    case high
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

  private func computedStagePenalty(stats: StageStats) -> Int {
    let deepDeficit = max(0, (15 - stats.deepPct) * 0.6)
    let remDeficit = max(0, (18 - stats.remPct) * 0.4)
    let awakeExcess = max(0, (stats.awakePct - 8) * 1.0)
    return min(Int(deepDeficit + remDeficit + awakeExcess), 15)
  }
}
