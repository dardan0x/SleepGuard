import Env
import Foundation
import Models
import Observation
import SleepCore

/// In-memory `HealthKitSyncing` for tests and previews. Never touches HealthKit.
///
///     @Test(.container) func example() async {
///       let fake = FakeHealthKitSync(isAuthorized: true, stages: [...])
///       Container.shared.healthKitSync.register { fake }
///       ...
///       #expect(fake.fetchedSessionIDs == [session.id])
///     }
@MainActor
@Observable
public final class FakeHealthKitSync: HealthKitSyncing {
  public var isAuthorized: Bool
  /// Returned by every `fetchSleepStages(for:)` call while authorized.
  public var stages: [SleepStageSegment]
  /// What `requestAuthorization()` grants.
  public var grantsAuthorization: Bool

  public private(set) var fetchedSessionIDs: [UUID] = []
  public private(set) var syncedSessionIDs: [UUID] = []
  public private(set) var authorizationRequests = 0

  public init(isAuthorized: Bool = false, stages: [SleepStageSegment] = [], grantsAuthorization: Bool = true) {
    self.isAuthorized = isAuthorized
    self.stages = stages
    self.grantsAuthorization = grantsAuthorization
  }

  public func requestAuthorization() async -> Bool {
    authorizationRequests += 1
    isAuthorized = grantsAuthorization
    return isAuthorized
  }

  public func checkAuthorizationStatus() {}

  public func fetchSleepStages(for session: SleepSession) async -> [SleepStageSegment] {
    fetchedSessionIDs.append(session.id)
    return isAuthorized ? stages : []
  }

  public func sync(session: SleepSession) async {
    guard isAuthorized else { return }
    syncedSessionIDs.append(session.id)
  }
}
