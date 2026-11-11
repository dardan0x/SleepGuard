import AudioEngine
import Foundation
import Observation

/// "Start recording in N minutes" countdown. Fake: `FakeRecordingDelayManager`.
@MainActor
public protocol RecordingDelayManaging: AnyObject, Observable {
  var isActive: Bool { get }
  var targetDate: Date? { get }
  var currentRemainingSeconds: Int { get }
  var remainingTimeString: String { get }
  func startDelay(minutes: Int)
  func cancel()
  func finish()
  func checkIfComplete() -> Bool
}
