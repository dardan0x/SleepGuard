import Foundation
import SleepCore
import SwiftData

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

  /// Recomputes every finished session whose cached score is missing or was
  /// produced by a different formula/config, then saves. Returns how many
  /// sessions changed. Run at launch, before anything reads cached scores.
  @discardableResult
  static func refreshStaleCachedScores(in context: ModelContext, config: SleepScoreConfig) throws -> Int {
    let version = SleepScore.cacheVersion(for: config)
    let stale = try context.fetch(FetchDescriptor<SleepSession>(
      predicate: #Predicate { $0.endDate != nil && (!$0.hasCachedScore || $0.cachedScoreVersion != version) }))
    guard !stale.isEmpty else { return 0 }
    for session in stale {
      session.refreshCachedScore(using: config)
    }
    try context.save()
    return stale.count
  }
}
