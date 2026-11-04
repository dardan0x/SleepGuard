import Env
import SwiftUI

public struct RecordingActionButton<Label: View>: View {
  let height: CGFloat
  let action: () -> Void
  let label: Label

  public init(
    height: CGFloat = 56,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label)
  {
    self.height = height
    self.action = action
    self.label = label()
  }

  public var body: some View {
    ZStack {
      // Outer soft halo
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(hex: "#FF453A").opacity(0.12))
        .frame(maxWidth: .infinity)
        .frame(height: height + 40)
        .blur(radius: 16)
        .offset(y: 6)

      // Inner concentrated glow
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [Color(hex: "#FF453A").opacity(0.35), Color(hex: "#FF453A").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom)
        )
        .frame(maxWidth: .infinity)
        .frame(height: height + 20)
        .blur(radius: 10)
        .offset(y: 8)

      Button(action: {
        HapticManager.shared.tap()
        action()
      }) {
        label
          .frame(maxWidth: .infinity)
          .frame(height: height)
          .background(
            ZStack {
              Color(hex: "#22232B")
              RoundedRectangle(cornerRadius: 16)
                .stroke(
                  LinearGradient(
                    colors: [Color(hex: "#FF453A").opacity(0.6), Color(hex: "#FF453A").opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing),
                  lineWidth: 1)
            }
          )
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
      .buttonStyle(ScaleButtonStyle())
    }
  }
}
