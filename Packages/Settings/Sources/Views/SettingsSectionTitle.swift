import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
struct SettingsSectionTitle: View {
  let text: String
  @Injected(\.theme) private var theme

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(theme.textTertiary)
      .tracking(1)
  }
}
