import Foundation
import Models
import Observation

/// Reads sleep stages from and writes sleep sessions to Apple Health.
///
/// Views resolve it as `any HealthKitSyncing` from the container
/// (`@Injected(\.healthKitSync)`); tests register `FakeHealthKitSync` from
/// `EnvTestSupport`.
@MainActor
public protocol HealthKitSyncing: AnyObject, Observable {
  /// Whether the user granted sharing for sleep analysis. Observable.
  var isAuthorized: Bool { get }
  func requestAuthorization() async -> Bool
  func checkAuthorizationStatus()
  /// Stages overlapping the session; empty when unavailable or not authorized.
  func fetchSleepStages(for session: SleepSession) async -> [SleepStageSegment]
  func sync(session: SleepSession) async
}
