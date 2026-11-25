import DesignSystem
import SwiftUI

@MainActor
struct RecordingsErrorView: View {
  @Environment(\.theme) private var theme
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.palette.textTertiary)

      Text(Strings.recordingsErrorTitle)
        .font(.headline)
        .foregroundStyle(theme.palette.textPrimary)

      Button(Strings.actionTryAgain) {
        onRetry()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(theme.palette.accent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
