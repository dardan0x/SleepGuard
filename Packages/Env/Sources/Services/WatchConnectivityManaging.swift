import Foundation
import Observation

/// Apple Watch reachability and sync status. Fake: `FakeWatchConnectivityManager`.
@MainActor
public protocol WatchConnectivityManaging: AnyObject, Observable {
  var isWatchReachable: Bool { get }
  var lastSyncedSession: Date? { get }
  func checkReachability()
}
