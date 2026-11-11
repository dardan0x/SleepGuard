import FactoryKit
import Foundation
import Models
import SwiftData

/// The live `SessionCommitting`.
@MainActor
public final class SessionCommitter: SessionCommitting {
  public static let shared = SessionCommitter()

  private let preferences: any UserPreferencesStoring
  private let appConfig: any AppConfigProviding
  private let pendingSessionStore: any PendingSessionStoring
  private let checkpointStore: any SessionCheckpointStoring
  private let storageLimitEnforcer: any StorageLimitEnforcing
  private let healthKitSync: any HealthKitSyncing

  public init(
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    appConfig: any AppConfigProviding = Container.shared.appConfig(),
    pendingSessionStore: any PendingSessionStoring = Container.shared.pendingSessionStore(),
    checkpointStore: any SessionCheckpointStoring = Container.shared.sessionCheckpointStore(),
    storageLimitEnforcer: any StorageLimitEnforcing = Container.shared.storageLimitEnforcer(),
    healthKitSync: any HealthKitSyncing = Container.shared.healthKitSync())
  {
    self.preferences = preferences
    self.appConfig = appConfig
    self.pendingSessionStore = pendingSessionStore
    self.checkpointStore = checkpointStore
    self.storageLimitEnforcer = storageLimitEnforcer
    self.healthKitSync = healthKitSync
  }

  @discardableResult
  public func commit(_ session: SleepSession, in context: ModelContext) throws -> Task<Void, Never> {
    for event in session.events ?? [] {
      context.insert(event)
    }
    context.insert(session)

    // Cache AFTER insertion so SwiftData tracks the mutations. Use the current
    // remote config so the cached score reflects the active formula.
    session.refreshCachedScore(using: appConfig.sleepScoreConfig)

    try context.save()

    // Only once the night is safely stored: the pending record lists this
    // night's clips, and a stale record gets its files deleted on the next
    // launch or recording. The checkpoint would offer to recover it again.
    pendingSessionStore.clearPending()
    checkpointStore.clear()

    let syncToHealthKit = preferences.syncToHealthKit
    return Task {
      _ = await storageLimitEnforcer.enforceLimits(modelContext: context)
      if syncToHealthKit {
        healthKitSync.checkAuthorizationStatus()
        await healthKitSync.sync(session: session)
      }
    }
  }
}
