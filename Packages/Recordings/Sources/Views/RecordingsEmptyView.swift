import DesignSystem
import Env
import FactoryKit
import SwiftUI

@MainActor
struct RecordingsEmptyView: View {
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsEmptyTitle)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text(Strings.recordingsEmptyMessage)
        .font(.system(size: 15))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
