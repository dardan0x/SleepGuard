import Models
import SwiftUI

/// "Score Impact" section of the sleep-stages info sheet: the scoring
/// formula, the computed stage penalty, and the deep/REM/awake threshold
/// bars with target markers.
struct ScoreImpactSection: View {
  let session: SleepSession
  let theme: Theme

  var body: some View {
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
              color: theme.stageDeepColor
            )
            thresholdBar(
              label: Strings.sleepStageRem,
              value: stats.remPct,
              target: 18,
              mode: .minimum,
              color: theme.stageREMColor
            )
            thresholdBar(
              label: Strings.sleepStageAwake,
              value: stats.awakePct,
              target: 8,
              mode: .maximum,
              color: theme.stageAwakeColor
            )
          }
          .padding(.top, 4)
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  private enum ThresholdMode {
    case minimum
    case maximum
  }

  private func thresholdBar(
    label: String,
    value: Double,
    target: Double,
    mode: ThresholdMode,
    color: Color
  ) -> some View {
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

  private func computedStagePenalty(stats: StageStats) -> Int {
    let deepDeficit = max(0, (15 - stats.deepPct) * 0.6)
    let remDeficit = max(0, (18 - stats.remPct) * 0.4)
    let awakeExcess = max(0, (stats.awakePct - 8) * 1.0)
    return min(Int(deepDeficit + remDeficit + awakeExcess), 15)
  }
}
