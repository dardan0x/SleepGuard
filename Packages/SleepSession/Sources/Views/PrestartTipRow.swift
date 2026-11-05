import DesignSystem
import FactoryKit
import SwiftUI

/// Single tip row: leading accent icon + guidance text.
struct PrestartTipRow: View {
  @Injected(\.theme) private var theme

  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(theme.accent)
        .frame(width: 24)

      Text(text)
        .font(.system(size: 16))
        .foregroundStyle(theme.textSecondary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}
