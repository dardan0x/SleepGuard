import SwiftUI

public struct StartRecordingButton: View {
  let action: () -> Void
  let height: CGFloat

  public init(height: CGFloat = 56, action: @escaping () -> Void) {
    self.height = height
    self.action = action
  }

  public var body: some View {
    RecordingActionButton(height: height, action: action) {
      HStack(spacing: 12) {
        PulsingDot()

        Text(Strings.actionStartRecording)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white.opacity(0.6))
      }
    }
  }
}

// MARK: - PulsingDot

private struct PulsingDot: View {
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(Color(hex: "#FF453A").opacity(0.25))
        .frame(width: 20, height: 20)
        .scaleEffect(isPulsing ? 1.4 : 1.0)
      Circle()
        .fill(Color(hex: "#FF453A"))
        .frame(width: 10, height: 10)
    }
    .onAppear { isPulsing = true }
    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
  }
}
