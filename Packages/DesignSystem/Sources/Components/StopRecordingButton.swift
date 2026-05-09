import SwiftUI

public struct StopRecordingButton: View {
  let action: () -> Void
  let height: CGFloat

  public init(height: CGFloat = 56, action: @escaping () -> Void) {
    self.height = height
    self.action = action
  }

  public var body: some View {
    RecordingActionButton(height: height, action: action) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: "#FF453A"))
          .frame(width: 12, height: 12)

        Text(Strings.sessionBedsideStopRecording)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
      }
    }
  }
}
