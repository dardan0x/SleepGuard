import DesignSystem
import SwiftUI

/// No saved night yet; the whole widget links to `sleepguard://start`.
struct LastNightEmptyView: View {
  let theme = Theme.shared

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "moon.zzz.fill")
        .font(.title2)
        .foregroundStyle(theme.accent)

      Text(Strings.widgetLastNightEmptyTitle)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.textPrimary)

      Text(Strings.widgetLastNightEmptyAction)
        .font(.caption)
        .foregroundStyle(theme.textSecondary)
    }
    .multilineTextAlignment(.center)
  }
}
