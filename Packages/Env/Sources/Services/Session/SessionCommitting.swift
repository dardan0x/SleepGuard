import Foundation
import Models
import SwiftData

/// Saves a finished night: the one owner of the most important write in the
/// app. Both the summary sheet and the force-save path (low battery) commit
/// through it. Fake: `FakeSessionCommitter`.
@MainActor
public protocol SessionCommitting: AnyObject {
  /// Inserts the session and its events, caches the score, saves, then clears
  /// the crash-recovery state and starts the follow-ups (storage limits,
  /// HealthKit sync).
  ///
  /// Throws when the save fails. Nothing is cleaned up in that case, so the
  /// pending files and the checkpoint still protect the night.
  ///
  /// Returns the follow-up work; callers don't need to wait for it.
  @discardableResult
  func commit(_ session: SleepSession, in context: ModelContext) throws -> Task<Void, Never>
}
