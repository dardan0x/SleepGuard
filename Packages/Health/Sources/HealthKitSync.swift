import Foundation
public import Models
public import Observation
public import SleepCore
public import SleepHealthKit

/// The live `HealthKitSyncing`: SleepGuard's observable service over the
/// shared `HealthKitSleep`, which decides what a night looks like in Apple
/// Health (the same in SleepGuardUIKitWay). This type adds what only this
/// app needs: the observable `isAuthorized` the screens read, the mapping
/// from `NightRecord`, and the logging.
@MainActor
@Observable
public final class HealthKitSync: HealthKitSyncing {
  public static let shared = HealthKitSync()

  private let health: HealthKitSleep

  public var isAuthorized = false

  public init(health: HealthKitSleep = HealthKitSleep()) {
    self.health = health
  }

  // MARK: - Authorization

  public func requestAuthorization() async -> Bool {
    do {
      isAuthorized = try await health.requestAuthorization()
    } catch {
      Log.session.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
      isAuthorized = false
    }
    return isAuthorized
  }

  public func checkAuthorizationStatus() {
    isAuthorized = health.canWrite
  }

  // MARK: - Read Sleep Stages

  /// Read whether or not writing is allowed: HealthKit never says whether
  /// reading is, and returns nothing when it isn't.
  public func fetchSleepStages(for session: NightRecord) async -> [SleepStageSegment] {
    let start = session.start
    let end = session.end
    do {
      return try await health.stages(from: start, to: end)
    } catch {
      Log.session.error("Reading sleep stages failed: \(error.localizedDescription, privacy: .public)")
      return []
    }
  }

  // MARK: - Write Sleep Data

  public func sync(session: NightRecord) async {
    do {
      try await health.save(session.night, summary: session.summary)
    } catch {
      Log.session.error("Writing the night to Health failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
