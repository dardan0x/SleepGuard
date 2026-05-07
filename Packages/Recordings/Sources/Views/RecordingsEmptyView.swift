import SwiftUI
import Env
import DesignSystem

@MainActor
struct RecordingsEmptyView: View {
  let theme: Theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text("No recordings yet")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text("Your sleep sessions will appear here after you start recording.")
        .font(.system(size: 15))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
