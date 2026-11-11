import FactoryKit
import SwiftUI

@MainActor
public struct StatCard: View {
  let icon: String
  let title: String
  let value: String
  @Injected(\.theme) private var theme
  /// `nil` uses the theme accent.
  let iconColor: Color?

  public init(
    icon: String,
    title: String,
    value: String,
    iconColor: Color? = nil)
  {
    self.icon = icon
    self.title = title
    self.value = value
    self.iconColor = iconColor
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(iconColor ?? theme.accent)

      VStack(alignment: .leading, spacing: 2) {
        Text(value)
          .font(.system(size: 16, weight: .bold, design: .rounded))
          .foregroundStyle(theme.textPrimary)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)

        Text(title)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(theme.textTertiary)
          .textCase(.uppercase)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(value)
  }
}
