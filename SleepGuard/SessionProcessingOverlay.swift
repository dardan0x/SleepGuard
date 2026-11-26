import DesignSystem
import SleepGuardDesignKit
import SleepStrings
import SwiftUI

/// Dimming overlay with a progress indicator shown while a finished session
/// is being processed after stop.
struct SessionProcessingOverlay: View {
  @Environment(\.theme) private var theme
  let isVisible: Bool

  var body: some View {
    if isVisible {
      ZStack {
        theme.palette.bgPrimary.opacity(0.6)
          .ignoresSafeArea()

        VStack(spacing: 16) {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: theme.palette.textPrimary))
            .scaleEffect(1.2)

          Text(Strings.processingSession)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
        }
        .padding(24)
        .background(theme.palette.bgCard)
        .cornerRadius(16)
      }
    }
  }
}
