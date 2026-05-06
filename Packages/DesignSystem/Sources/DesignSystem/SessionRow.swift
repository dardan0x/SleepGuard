import SwiftUI

@MainActor
public struct SessionRow: View {
  let dayNumber: String
  let weekday: String
  let duration: String
  let events: String
  let intensityColor: Color
  let theme: Theme

  public init(
    dayNumber: String,
    weekday: String,
    duration: String,
    events: String,
    intensityColor: Color,
    theme: Theme
  ) {
    self.dayNumber = dayNumber
    self.weekday = weekday
    self.duration = duration
    self.events = events
    self.intensityColor = intensityColor
    self.theme = theme
  }

  public var body: some View {
    HStack(spacing: 16) {
      dateColumn

      infoColumn

      Spacer()

      indicatorColumn
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var dateColumn: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(dayNumber)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundStyle(theme.textPrimary)

      Text(weekday)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)
    }
  }

  private var infoColumn: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(duration)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text(events)
        .font(.system(size: 13))
        .foregroundStyle(theme.textSecondary)
    }
  }

  private var indicatorColumn: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(intensityColor)
        .frame(width: 10, height: 10)

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
    }
  }
}
