import Foundation
public import SleepCore

/// The night in progress on disk, for crash recovery: a `Night` in
/// SleepGuardShared's checkpoint format (`NightCheckpoint`), the same file
/// SleepGuardUIKitWay writes. Fake: `FakeSessionCheckpointStore`.
@MainActor
public protocol SessionCheckpointStoring: AnyObject {
  func write(_ night: Night)
  /// The night, when there is one worth recovering (it has events).
  func loadIfPresent() -> Night?
  func clear()
}
