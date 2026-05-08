import SwiftUI
import DesignSystem

struct BedsideClockBadgesView: View {
  let eventsCount: Int
  let isAlarmSet: Bool
  let alarmTimeString: String
  @Environment(Theme.self) private var theme

  var body: some View {
    HStack {
      if isAlarmSet {
        alarmBadge
      }

      Spacer()

      eventBadge
    }
    .padding(.top, 16)
    .padding(.horizontal, 24)
  }

  private var eventBadge: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(theme.scoreGreen)
        .frame(width: 8, height: 8)
      Text("\(eventsCount) EVENTS")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.scoreGreen)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .overlay(
      RoundedRectangle(cornerRadius: 100)
        .stroke(theme.scoreGreen, lineWidth: 1)
    )
  }

  private var alarmBadge: some View {
    HStack(spacing: 6) {
      Image(systemName: "alarm.fill")
        .font(.system(size: 12))
        .foregroundStyle(theme.accent)
      Text(alarmTimeString)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.accent)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .overlay(
      RoundedRectangle(cornerRadius: 100)
        .stroke(theme.accent, lineWidth: 1)
    )
  }
}
