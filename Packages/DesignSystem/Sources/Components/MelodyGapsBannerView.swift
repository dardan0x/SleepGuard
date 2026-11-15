import Models
import SwiftUI

/// The shared kit's recording-gap banner, shown when the Snore Interrupter
/// paused detection during `session`.
public struct MelodyGapsBannerView: View {
  public let session: SleepSession

  public init(session: SleepSession) {
    self.session = session
  }

  public var body: some View {
    if let gaps = session.recordingGaps, !gaps.isEmpty {
      RecordingGapsBanner(totalGap: gaps.reduce(0) { $0 + $1.duration })
    }
  }
}
