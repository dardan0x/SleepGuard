import DesignSystem
import SwiftUI

@MainActor
struct SettingsSectionTitle: View {
  let text: String
  @Environment(Theme.self) private var theme

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(theme.textTertiary)
      .tracking(1)
  }
}
