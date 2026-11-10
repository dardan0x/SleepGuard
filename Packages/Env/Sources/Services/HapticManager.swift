import UIKit

/// Haptic feedback. Fake: `FakeHapticManager` (records calls).
@MainActor
public protocol HapticFeedbackProviding: AnyObject {
  func prepare()
  func nudge()
  func tap()
}

/// Provides haptic feedback for user-facing events.
@MainActor
public final class HapticManager: HapticFeedbackProviding {
  public static let shared = HapticManager()

  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)

  public init() {}

  public func prepare() {
    impactGenerator.prepare()
    lightImpactGenerator.prepare()
  }

  /// Fires a strong impact nudge (used during Snore Interrupter playback).
  public func nudge() {
    impactGenerator.impactOccurred(intensity: 1.0)
  }

  /// Fires a light tap (used for button presses).
  public func tap() {
    lightImpactGenerator.prepare()
    lightImpactGenerator.impactOccurred(intensity: 0.8)
  }
}
