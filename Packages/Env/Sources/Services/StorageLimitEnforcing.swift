import Foundation
import Models
import SwiftData

/// Deletes old audio to honor the user's storage limits. Fake: `FakeStorageLimitEnforcer`.
/// Nonisolated and `Sendable`; the SwiftData work is `@MainActor`.
public protocol StorageLimitEnforcing: Sendable {
  @MainActor
  @discardableResult
  func enforceLimits(modelContext: ModelContext) async -> CleanupReport
  #if DEBUG
  @MainActor
  func injectDummyAudioForTesting(modelContext: ModelContext) -> Int
  #endif
}
