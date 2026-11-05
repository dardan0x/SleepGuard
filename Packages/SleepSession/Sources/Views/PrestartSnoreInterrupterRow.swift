import DesignSystem
import FactoryKit
import SwiftUI

/// Settings-style navigation row used on the prestart screen for the Snore
/// Interrupter: icon, title, current value, optional lockscreen note.
struct PrestartSnoreInterrupterRow: View {
  @Injected(\.theme) private var theme

  let icon: String
  let title: String
  let value: String
  var subtitle: String? = nil
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        HStack(spacing: 12) {
          Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundStyle(theme.accent)
            .frame(width: 24)

          Text(title)
            .font(.system(size: 16))
            .foregroundStyle(theme.textPrimary)

          Spacer()

          Text(value)
            .font(.system(size: 16))
            .foregroundStyle(theme.textSecondary)

          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
        }

        if let subtitle {
          HStack(spacing: 6) {
            Image(systemName: "lock.open.fill")
              .font(.system(size: 12))
            Text(subtitle)
              .font(.system(size: 13))
            Spacer()
          }
          .foregroundStyle(theme.textTertiary)
          .padding(.top, 4)
          .padding(.leading, 6)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, subtitle == nil ? 14 : 12)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)
    }
    .buttonStyle(.plain)
  }
}
