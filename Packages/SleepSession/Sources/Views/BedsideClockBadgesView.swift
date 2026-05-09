import SwiftUI
import DesignSystem

struct BedsideClockBadgesView: View {
  let eventsCount: Int
  @Environment(Theme.self) private var theme

  var body: some View {
    HStack {
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
      Text(String(format: Strings.sessionRecordingEventsCountUpperFormat, eventsCount))
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

}
