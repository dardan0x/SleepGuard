import DesignSystem
import FactoryKit
import SwiftUI

/// Band-pass + per-clip peak normalization toggle shown below the player.
/// The binding's setter persists the choice; this view only renders it.
struct EnhancedAudioToggleSection: View {
  @Injected(\.theme) private var theme

  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(Strings.eventPlayerEnhancedAudioLabel)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textPrimary)
        Text(Strings.eventPlayerEnhancedAudioDescription)
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
      }
      Spacer(minLength: 0)
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .tint(theme.accent)
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}
