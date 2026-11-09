import Foundation
import Testing
@testable import Env

/// Only the side-effect-free parts. `startDelay`, `cancel` and the completion
/// path call `UNUserNotificationCenter.current()` (throws without an app bundle,
/// as in package tests) and start/stop the microphone warm-up.
@MainActor
@Suite(.serialized)
struct RecordingDelayManagerTests {
  private let manager = RecordingDelayManager.shared

  /// Each test gets a fresh instance, so reset the shared state here.
  init() {
    manager.isActive = false
    manager.targetDate = nil
    manager.currentRemainingSeconds = 0
  }

  @Test(arguments: [(0, "00:00"), (5, "00:05"), (65, "01:05"), (600, "10:00"), (5999, "99:59"), (6000, "100:00")])
  func remainingTimeIsMinutesAndSeconds(seconds: Int, expected: String) {
    manager.currentRemainingSeconds = seconds
    #expect(manager.remainingTimeString == expected)
  }

  @Test func inactiveDelayIsNeverComplete() {
    manager.isActive = false
    manager.targetDate = Date().addingTimeInterval(-60)
    #expect(!manager.checkIfComplete())
  }

  @Test func activeDelayWithoutTargetIsNotComplete() {
    manager.isActive = true
    manager.targetDate = nil
    #expect(!manager.checkIfComplete())
  }

  @Test func activeDelayBeforeItsTargetIsNotComplete() {
    manager.isActive = true
    manager.targetDate = Date().addingTimeInterval(60)
    #expect(!manager.checkIfComplete())
    #expect(manager.isActive)
  }
}
