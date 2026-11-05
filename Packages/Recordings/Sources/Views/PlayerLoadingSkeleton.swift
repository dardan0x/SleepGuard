import DesignSystem
import FactoryKit
import SwiftUI

/// Placeholder shown while the player is being set up (clip controller load
/// or legacy export). Mimics the rough shape of `EventPlayerView` so the
/// sheet layout doesn't jump when it transitions to the real player.
struct PlayerLoadingSkeleton: View {
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 20) {
      RoundedRectangle(cornerRadius: theme.radiusSmall)
        .fill(theme.bgElevated)
        .frame(height: 80)

      VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 2)
          .fill(theme.bgElevated)
          .frame(height: 4)
        HStack {
          Text("0:00")
            .font(.system(size: 12, weight: .medium))
          Spacer()
          Text("0:00")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(theme.textTertiary)
      }

      HStack(spacing: 28) {
        Circle().fill(theme.bgElevated).frame(width: 44, height: 44)
        Circle().fill(theme.bgElevated).frame(width: 64, height: 64)
        Circle().fill(theme.bgElevated).frame(width: 44, height: 44)
      }
      .padding(.top, 4)

      ProgressView()
        .progressViewStyle(.circular)
        .tint(theme.accent)
        .padding(.top, 4)
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}
