import DesignSystem
import SleepCore
import SwiftData
public import SwiftUI

/// The morning briefing sheet: the shared `BriefingContent`. A survey answer
/// is kept, then the sheet closes.
public struct BriefingSheet: View {
  let presented: PresentedBriefing
  let controller: BriefingController
  @Environment(\.dismiss) private var dismiss

  public init(presented: PresentedBriefing, controller: BriefingController) {
    self.presented = presented
    self.controller = controller
  }

  public var body: some View {
    BriefingContent(
      briefing: presented.briefing,
      onChip: { chip in
        controller.save(chip, for: presented)
        dismiss()
      },
      onClose: { dismiss() })
  }
}
