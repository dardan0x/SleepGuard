import DesignSystem
import SwiftUI

/// Prestart screen header: moon icon tile + title and body copy.
struct PrestartHeaderView: View {
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: DeviceSize.isCompactHeight ? 20 : 24)
        .fill(theme.bgCard)
        .frame(width: DeviceSize.isCompactHeight ? 80 : 100, height: DeviceSize.isCompactHeight ? 80 : 100)
        .overlay(
          Image(systemName: "moon.fill")
            .font(.system(size: DeviceSize.isCompactHeight ? 36 : 44))
            .foregroundStyle(theme.accent)
        )

      Text(Strings.statsEmptyTitle)
        .font(.system(size: DeviceSize.isCompactHeight ? 22 : 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text(Strings.sessionPrestartBody)
        .font(.system(size: DeviceSize.isCompactHeight ? 14 : 16))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
