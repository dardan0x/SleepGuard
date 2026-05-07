import SwiftUI
import Env
import DesignSystem

@MainActor
struct RecordingsErrorView: View {
  let theme: Theme
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text("Something went wrong")
        .font(.headline)
        .foregroundStyle(theme.textPrimary)

      Button("Try Again") {
        onRetry()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(theme.accent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
