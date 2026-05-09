import SwiftUI

public struct SnoringLegendView: View {
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    HStack(spacing: 16) {
      legendItem(color: theme.snoreQuiet, label: Strings.statsCalendarIntensityQuiet)
      legendItem(color: theme.snoreLight, label: Strings.settingsThemeLight)
      legendItem(color: theme.snoreLoud, label: Strings.statsCalendarIntensityLoud)
    }
    .frame(maxWidth: .infinity)
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)

      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(theme.textSecondary)
    }
  }
}
