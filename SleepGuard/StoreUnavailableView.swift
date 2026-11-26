import DesignSystem
import SleepGuardDesignKit
import SleepStrings
import SwiftUI

/// Shown instead of the app when the on-disk store couldn't be opened. The
/// store file is kept, so an update that can read it brings the nights back.
/// Blocks everything else, so nothing is recorded into the in-memory fallback.
/// Laid out like the hard update gate (`UpdateGateView`).
struct StoreUnavailableView: View {
  let openAppStore: () -> Void

  @Environment(\.theme) private var theme
  var body: some View {
    ZStack {
      theme.palette.bgPrimary
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "externaldrive.badge.exclamationmark")
          .font(.system(size: 48))
          .foregroundStyle(theme.palette.accent)
          .accessibilityHidden(true)

        Text(Strings.storeUnavailableTitle)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.storeUnavailableMessage)
          .font(.system(size: 15))
          .foregroundStyle(theme.palette.textSecondary)
          .multilineTextAlignment(.center)

        Button(action: openAppStore) {
          Text(Strings.storeUnavailableUpdate)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.small))
        }
        .buttonStyle(.plain)
      }
      .padding(28)
      .background(theme.palette.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
      .padding(.horizontal, 32)
    }
  }
}
