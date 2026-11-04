import DesignSystem
import SwiftUI

struct BedsideClockStatusView: View {
  let statusLabel: String
  let snoringColor: Color
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 6) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 14))
          .foregroundStyle(snoringColor)
        Text(statusLabel)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(snoringColor)
      }

      // dB and confidence removed from active recording UI — values are
      // negative during recording which is confusing to users.
    }
  }
}
