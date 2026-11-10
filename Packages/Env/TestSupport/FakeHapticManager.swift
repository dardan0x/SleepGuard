import Env

/// Records haptic calls instead of playing them.
@MainActor
public final class FakeHapticManager: HapticFeedbackProviding {
  public private(set) var calls: [String] = []

  public init() {}

  public func prepare() { calls.append("prepare") }
  public func nudge() { calls.append("nudge") }
  public func tap() { calls.append("tap") }
}
