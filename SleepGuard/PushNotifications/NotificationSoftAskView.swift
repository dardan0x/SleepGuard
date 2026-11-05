import DesignSystem
import Env
import SwiftUI

/// Pre-permission explainer shown before the iOS system dialog. Only triggers
/// the real request if the user taps Enable, so a "Don't Allow" isn't burned
/// on an unexplained prompt.
struct NotificationSoftAskView: View {
  let theme = Theme.shared
  let permissions = NotificationPermissionManager.shared
  let userPreferences = UserPreferences.shared
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "bell.badge.fill")
        .font(.system(size: 48))
        .foregroundStyle(theme.accent)

      Text(Strings.notificationsSoftAskTitle)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text(Strings.notificationsSoftAskBody)
        .font(.system(size: 15))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)

      Button {
        Task {
          await permissions.requestAuthorization()
          finish()
        }
      } label: {
        Text(Strings.notificationsSoftAskEnable)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(theme.accent)
          .clipShape(RoundedRectangle(cornerRadius: theme.radiusSmall))
      }
      .buttonStyle(.plain)

      Button {
        finish()
      } label: {
        Text(Strings.notificationsSoftAskLater)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
      .buttonStyle(.plain)
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.bgPrimary)
  }

  private func finish() {
    userPreferences.notificationSoftAskDismissed = true
    onClose()
  }
}
