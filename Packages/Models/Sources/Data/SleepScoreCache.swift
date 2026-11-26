import Foundation
public import SleepCore
public import SleepStore
public import SwiftData

public extension NightRecord {
  /// Recomputes every saved night whose stored summary is missing or was made
  /// by a different formula/config, a batch at a time: it saves and yields
  /// the main actor after each batch, so a long history never stalls the
  /// first frames, and screens update as batches land. Returns how many
  /// nights changed. Run at launch.
  ///
  /// It runs on the main context on purpose: saves from a background context
  /// don't refresh objects the main context already holds, so `@Query` screens
  /// would keep the old scores until the next launch (seen on the simulator).
  @MainActor
  @discardableResult
  static func refreshStaleSummaries(
    in context: ModelContext,
    config: SleepScoreConfig,
    batchSize: Int = 50) async throws -> Int
  {
    let version = SleepScore.cacheVersion(for: config)
    var refreshed = 0
    while true {
      // Each pass stamps the current version, so the next fetch moves on.
      let stale = try SleepStore.staleNights(in: context, version: version, limit: batchSize)
      guard !stale.isEmpty else { return refreshed }
      for night in stale {
        night.refreshSummary(using: config)
      }
      try context.save()
      refreshed += stale.count
      await Task.yield()
    }
  }
}
