import SwiftUI
import DesignSystem

@MainActor
public struct StatCard: View {
  let icon: String
  let title: String
  let value: String
  let theme: Theme
  let iconColor: Color

  public init(
    icon: String,
    title: String,
    value: String,
    theme: Theme,
    iconColor: Color? = nil
  ) {
    self.icon = icon
    self.title = title
    self.value = value
    self.theme = theme
    self.iconColor = iconColor ?? theme.primaryColor
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(iconColor)

      VStack(alignment: .leading, spacing: 2) {
        Text(value)
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .foregroundStyle(theme.labelColor)
          .lineLimit(1)

        Text(title)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.secondaryLabelColor)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.surfaceColor)
    .cornerRadius(12)
  }
}
