import DesignSystem
import FactoryKit
import SwiftUI

struct BedsideClockClockView: View {
  let timeString: String
  let dateString: String
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 8) {
      Text(timeString)
        .font(.system(size: 96, weight: .thin, design: .rounded))
        .foregroundStyle(theme.textTertiary)
        .minimumScaleFactor(0.5)
        .monospacedDigit()

      Text(dateString)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(theme.textSecondary)
        .tracking(2)
        .textCase(.uppercase)
    }
  }
}
