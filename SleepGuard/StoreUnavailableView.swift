import DesignSystem
import SwiftUI

/// Shown instead of the app when the on-disk store couldn't be opened. The
/// store file is kept, so an update that can read it brings the nights back.
/// Blocks everything else, so nothing is recorded into the in-memory fallback.
/// Laid out like the hard update gate (`UpdateGateView`).
struct StoreUnavailableView: View {
  let openAppStore: () -> Void

  private let theme = AppTheme.shared

  var body: some View {
    ZStack {
      theme.bgPrimary
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "externaldrive.badge.exclamationmark")
          .font(.system(size: 48))
          .foregroundStyle(theme.accent)
          .accessibilityHidden(true)

        Text(Strings.storeUnavailableTitle)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.storeUnavailableMessage)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        Button(action: openAppStore) {
          Text(Strings.storeUnavailableUpdate)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusSmall))
        }
        .buttonStyle(.plain)
      }
      .padding(28)
      .background(theme.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radiusCard))
      .padding(.horizontal, 32)
    }
  }
}
