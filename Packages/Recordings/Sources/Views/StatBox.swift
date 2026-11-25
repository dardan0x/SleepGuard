import DesignSystem
import SwiftUI

/// Small labeled value box used by the advanced player's stats grid.
struct StatBox: View {
  let title: String
  let value: String
  @Environment(\.theme) private var theme
  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(theme.palette.textPrimary)
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.palette.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(theme.palette.bgElevated)
    .cornerRadius(theme.radii.small)
  }
}
