import SwiftUI
import Models
import Env
import DesignSystem

struct CalendarSelectedNightView: View {
  let session: SleepSession
  let selectedDateString: String
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.statsCalendarSelectedNightLabel)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      HStack(spacing: 12) {
        SleepScoreGauge(score: session.sleepScore, theme: theme, size: 44)

        VStack(alignment: .leading, spacing: 2) {
          Text(selectedDateString)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(theme.textPrimary)

          Text(sessionDescription)
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)
      .contentShape(Rectangle())
      .onTapGesture {
        routerPath.navigate(to: .sessionDetail(id: session.id))
      }
    }
  }

  private var sessionDescription: String {
    let intensity: String
    if let events = session.events, !events.isEmpty {
      let loud = events.filter { $0.intensity == .loud }.count
      let light = events.filter { $0.intensity == .light }.count
      if loud > 0 { intensity = Strings.statsCalendarLegendLoud }
      else if light > 0 { intensity = Strings.statsCalendarLegendLight }
      else { intensity = Strings.statsCalendarIntensityQuiet }
    } else {
      intensity = "Quiet"
    }
    return "\(intensity) · score \(session.sleepScore)"
  }
}
