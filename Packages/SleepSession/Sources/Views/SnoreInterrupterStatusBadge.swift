import DesignSystem
import FactoryKit
import SwiftUI

/// Enabled/disabled capsule badge under the Snore Interrupter controls.
struct SnoreInterrupterStatusBadge: View {
  @Injected(\.theme) private var theme

  let isEnabled: Bool

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(theme.accent)
        .frame(width: 6, height: 6)

      Text(isEnabled ? Strings.soundEnabledSnoreInterrupterSheet : Strings.soundDisabledSnoreInterrupterSheet)
        .font(.system(size: 12))
        .foregroundStyle(theme.accent)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 10)
    .background(theme.accent.opacity(0.2))
    .overlay(
      Capsule()
        .stroke(theme.accent, lineWidth: 1)
    )
    .clipShape(Capsule())
  }
}
