import SwiftUI
import Env
import DesignSystem

@MainActor
struct TrendStatCard: View {
  let icon: String
  let iconColor: Color
  let label: String
  let value: String
  let theme: Theme

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 12))
          .foregroundStyle(iconColor)

        Text(label)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(0.5)
      }

      Text(value)
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.bgCard)
    .cornerRadius(12)
  }
}
