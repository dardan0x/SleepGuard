import Models
import SwiftUI

/// The shared kit's low-battery banner, shown when `session` was saved early
/// because the battery ran low.
public struct LowBatteryBannerView: View {
  public let session: SleepSession

  public init(session: SleepSession) {
    self.session = session
  }

  public var body: some View {
    if session.terminationReason == "low_battery" {
      LowBatteryBanner()
    }
  }
}
