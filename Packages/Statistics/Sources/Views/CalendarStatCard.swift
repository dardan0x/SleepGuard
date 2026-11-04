import DesignSystem
import Env
import SwiftUI

@MainActor
struct CalendarStatCard: View {
  let icon: String
  let label: String
  let value: String
  let theme: Theme

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: 12))
        .foregroundStyle(theme.textTertiary)

      Text(value)
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .foregroundStyle(theme.textPrimary)

      Text(label)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(0.5)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(theme.bgCard)
    .cornerRadius(12)
  }
}
