import Foundation
import SwiftData

public extension SleepScore {
  /// Bump when the formula's *code* changes (a new penalty, different episode
  /// merging, gap rules). Coefficient changes don't need a bump: they change
  /// the config fingerprint in `cacheVersion(for:)`.
  static let formulaVersion = 1

  /// Identifies the formula + config that produced a cached score:
  /// `"<formulaVersion>-<config fingerprint>"`. A session whose
  /// `cachedScoreVersion` differs is stale.
  static func cacheVersion(for config: SleepScoreConfig) -> String {
    "\(formulaVersion)-\(String(fingerprint(of: config), radix: 16))"
  }

  /// FNV-1a over the config's sorted-key JSON. Unlike `hashValue`, it is the
  /// same on every launch, so it can be persisted.
  private static func fingerprint(of config: SleepScoreConfig) -> UInt64 {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = (try? encoder.encode(config)) ?? Data()
    return data.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
  }
}

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
