import Foundation
public import Models
public import Observation
public import SleepCore
public import SleepStore

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
  func fetchSleepStages(for session: NightRecord) async -> [SleepStageSegment]
  func sync(session: NightRecord) async
}
