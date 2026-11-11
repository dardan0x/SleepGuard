import Foundation
import Models

/// Crash-recovery snapshot file. Fake: `FakeSessionCheckpointStore`.
@MainActor
public protocol SessionCheckpointStoring: AnyObject {
  func write(_ snapshot: SessionRecoverySnapshot)
  func loadIfPresent() -> SessionRecoverySnapshot?
  func clear()
}
