import DesignSystem
import SwiftUI

struct StatisticsLoadedHeaderView: View {
  let onViewCalendar: () -> Void
  @Environment(\.theme) private var theme
  var body: some View {
    HStack {
      Text(Strings.tabStatistics)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)

      Spacer()

      Button {
        onViewCalendar()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .font(.system(size: 14, weight: .medium))
          Text(Strings.watchCalendar)
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(theme.palette.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(theme.palette.bgCard)
        )
      }
    }
  }
}
