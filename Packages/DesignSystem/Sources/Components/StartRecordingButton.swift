import SwiftUI

// MARK: - Generic base

public struct RecordingActionButton<Label: View>: View {
  let height: CGFloat
  let action: () -> Void
  let label: Label

  public init(
    height: CGFloat = 56,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
  ) {
    self.height = height
    self.action = action
    self.label = label()
  }

  public var body: some View {
    ZStack {
      // Outer soft halo
      Capsule()
        .fill(Color(hex: "#FF453A").opacity(0.12))
        .frame(maxWidth: .infinity)
        .frame(height: height + 40)
        .blur(radius: 20)
        .offset(y: 6)

      // Inner concentrated glow
      Capsule()
        .fill(
          LinearGradient(
            colors: [Color(hex: "#FF453A").opacity(0.45), Color(hex: "#FF453A").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(maxWidth: .infinity)
        .frame(height: height + 20)
        .blur(radius: 10)
        .offset(y: 8)

      Button(action: action) {
        label
          .frame(maxWidth: .infinity)
          .frame(height: height)
          .background(
            ZStack {
              Color(hex: "#1E1D1E")
              Capsule()
                .stroke(
                  LinearGradient(
                    colors: [Color(hex: "#FF453A").opacity(0.6), Color(hex: "#FF453A").opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                  ),
                  lineWidth: 1
                )
            }
          )
          .clipShape(Capsule())
      }
    }
  }
}

// MARK: - Start Recording

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

        Text("Start Recording")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white.opacity(0.6))
      }
    }
  }
}

// MARK: - Stop Recording

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

        Text("Stop Recording")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
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
