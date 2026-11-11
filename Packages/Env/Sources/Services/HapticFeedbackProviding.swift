import Foundation

/// Haptic feedback. Fake: `FakeHapticManager` (records calls).
@MainActor
public protocol HapticFeedbackProviding: AnyObject {
  func prepare()
  func nudge()
  func tap()
}
