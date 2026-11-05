import FactoryKit
import Models
import SwiftUI

public struct LowBatteryBannerView: View {
  public let session: SleepSession

  @Injected(\.theme) private var theme

  public init(session: SleepSession) {
    self.session = session
  }

  public var body: some View {
    if let reason = session.terminationReason, reason == "low_battery" {
      HStack(spacing: 10) {
        Image(systemName: "bolt.fill")
          .font(.system(size: 14))
          .foregroundStyle(theme.scoreAmber)

        Text(Strings.sessionSummaryLowBatteryForceSaveInfo)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusSmall)
    } else {
      EmptyView()
    }
  }
}
