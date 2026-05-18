import SwiftUI
import Models

public struct MelodyGapsBannerView: View {
  public let session: SleepSession

  @Environment(Theme.self) private var theme

  public init(session: SleepSession) {
    self.session = session
  }

  public var body: some View {
    if let gaps = session.recordingGaps, !gaps.isEmpty {
      let totalGapDuration = gaps.reduce(0) { $0 + $1.duration }

      HStack(spacing: 10) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 14))
          .foregroundStyle(theme.accent)

        Text(String(format: Strings.sessionSummaryMelodyGapsInfo, durationString(totalGapDuration)))
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusSmall)
    } else {
      EmptyView()
    }
  }

  private func durationString(_ total: TimeInterval) -> String {
    let totalInt = Int(total)
    let hours = totalInt / 3600
    let minutes = (totalInt % 3600) / 60
    let seconds = totalInt % 60
    if hours > 0 {
      let hourLabel = hours == 1 ? Strings.timeHourSingular : Strings.timeHourPlural
      let minLabel = minutes == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
      return "\(Strings.commonOver) \(hours) \(hourLabel) \(minutes) \(minLabel)"
    }
    if minutes > 0 {
      let minLabel = minutes == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
      return "\(Strings.commonOver) \(minutes) \(minLabel)"
    }
    return "\(Strings.commonOver) \(seconds) \(Strings.settingsUnitSecondsShort)"
  }
}
