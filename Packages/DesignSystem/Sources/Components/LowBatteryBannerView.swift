public import Models
public import SwiftUI
public import SleepStore
import SleepGuardDesignKit

/// The shared kit's low-battery banner, shown when `session` was saved early
/// because the battery ran low.
public struct LowBatteryBannerView: View {
  public let session: NightRecord

  public init(session: NightRecord) {
    self.session = session
  }

  public var body: some View {
    if session.endReason == .lowBattery {
      LowBatteryBanner()
    }
  }
}
