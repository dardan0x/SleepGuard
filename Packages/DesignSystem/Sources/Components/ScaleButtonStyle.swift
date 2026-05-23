import SwiftUI

/// A subtle press animation that scales the button down and dims it slightly.
public struct ScaleButtonStyle: ButtonStyle {
  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}
