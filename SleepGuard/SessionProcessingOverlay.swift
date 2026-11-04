import Env
import DesignSystem
import SwiftUI

/// Dimming overlay with a progress indicator shown while a finished session
/// is being processed after stop.
struct SessionProcessingOverlay: View {
  @Environment(Theme.self) private var theme

  let isVisible: Bool

  var body: some View {
    if isVisible {
      ZStack {
        theme.bgPrimary.opacity(0.6)
          .ignoresSafeArea()

        VStack(spacing: 16) {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: theme.textPrimary))
            .scaleEffect(1.2)

          Text(Strings.processingSession)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.textPrimary)
        }
        .padding(24)
        .background(theme.bgCard)
        .cornerRadius(16)
      }
    }
  }
}
