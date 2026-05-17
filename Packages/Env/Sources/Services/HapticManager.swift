import UIKit

/// Provides haptic feedback for user-facing events.
@MainActor
public final class HapticManager {
  public static let shared = HapticManager()

  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

  private init() {}

  public func prepare() {
    impactGenerator.prepare()
  }

  /// Fires a strong impact nudge (used during soothing melody playback).
  public func nudge() {
    impactGenerator.impactOccurred(intensity: 1.0)
  }
}
