import Foundation
public import SleepCore
public import SwiftData

public extension SleepSession {
  /// The single writer of the cached score fields. Recomputes from events
  /// (so it faults the `events` relationship) and stamps the formula version.
  ///
  /// Call it after `modelContext.insert(session)`: SwiftData doesn't track
  /// changes made before insertion. The caller saves.
  func refreshCachedScore(using config: SleepScoreConfig) {
    // Clear the flag first so `snoringDuration` recomputes instead of
    // returning the old cached value.
    hasCachedScore = false
    let inputs = sleepInputs
    cachedSnoringDuration = inputs.snoringDuration
    cachedSleepScore = SleepScore.compute(inputs, config: config)
    cachedScoreVersion = SleepScore.cacheVersion(for: config)
    hasCachedScore = true
  }

  /// Whether the cached score is missing or was produced by another
  /// formula/config. Reads only the cached fields (no faulting).
  func hasStaleCachedScore(for config: SleepScoreConfig) -> Bool {
    !hasCachedScore || cachedScoreVersion != SleepScore.cacheVersion(for: config)
  }

  /// Recomputes every finished session whose cached score is missing or was
  /// produced by a different formula/config, a batch at a time: it saves and
  /// yields the main actor after each batch, so a long history never stalls the
  /// first frames, and screens update as batches land. Returns how many
  /// sessions changed. Run at launch.
  ///
  /// It runs on the main context on purpose: saves from a background context
  /// don't refresh objects the main context already holds, so `@Query` screens
  /// would keep the old scores until the next launch (seen on the simulator).
  @MainActor
  @discardableResult
  static func refreshStaleCachedScores(
    in context: ModelContext,
    config: SleepScoreConfig,
    batchSize: Int = 50) async throws -> Int
  {
    let version = SleepScore.cacheVersion(for: config)
    var descriptor = FetchDescriptor<SleepSession>(
      predicate: #Predicate { $0.endDate != nil && (!$0.hasCachedScore || $0.cachedScoreVersion != version) })
    descriptor.fetchLimit = batchSize
    var refreshed = 0
    while true {
      // Each pass stamps the current version, so the next fetch moves on.
      let stale = try context.fetch(descriptor)
      guard !stale.isEmpty else { return refreshed }
      for session in stale {
        session.refreshCachedScore(using: config)
      }
      try context.save()
      refreshed += stale.count
      await Task.yield()
    }
  }
}
