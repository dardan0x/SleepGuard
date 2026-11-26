import DesignSystem
import SleepGuardDesignKit
import SleepStrings
import SwiftUI

/// No saved night yet; the whole widget links to `sleepguard://start`.
struct WidgetEmptyView: View {
  @Environment(\.theme) private var theme
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "moon.zzz.fill")
        .font(.title2)
        .foregroundStyle(theme.palette.accent)

      Text(Strings.widgetLastNightEmptyTitle)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.palette.textPrimary)

      Text(Strings.widgetLastNightEmptyAction)
        .font(.caption)
        .foregroundStyle(theme.palette.textSecondary)
    }
    .multilineTextAlignment(.center)
  }
}
