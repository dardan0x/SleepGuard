import SwiftUI
import Env
import DesignSystem

@MainActor
struct StatisticsErrorView: View {
  let theme: Theme
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsErrorTitle)
        .font(.headline)
        .foregroundStyle(theme.textPrimary)

      Button(Strings.actionTryAgain) {
        onRetry()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(theme.accent)
    }
    .toolbar(.hidden, for: .navigationBar)
  }
}
