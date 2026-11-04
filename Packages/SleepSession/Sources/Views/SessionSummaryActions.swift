import DesignSystem
import SwiftUI

/// The glowing "Save Session" capsule + the plain Discard button on the
/// session summary screen.
struct SessionSummaryActions: View {
  @Environment(Theme.self) private var theme

  let onSave: () -> Void
  let onDiscard: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        // Outer soft halo
        Capsule()
          .fill(theme.accent.opacity(0.12))
          .frame(maxWidth: .infinity)
          .frame(height: 96)
          .blur(radius: 20)
          .offset(y: 6)

        // Inner concentrated glow
        Capsule()
          .fill(
            LinearGradient(
              colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.0)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(maxWidth: .infinity)
          .frame(height: 76)
          .blur(radius: 10)
          .offset(y: 8)

        Button(action: onSave) {
          Text(Strings.actionSaveSession)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
              ZStack {
                Color(hex: "#1E1D1E")
                Capsule()
                  .stroke(
                    LinearGradient(
                      colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                      startPoint: .leading,
                      endPoint: .trailing
                    ),
                    lineWidth: 1
                  )
              }
            )
            .clipShape(Capsule())
        }
      }

      Button(action: onDiscard) {
        Text(Strings.actionDiscard)
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
    }
  }
}
