import Foundation
import Observation
import Platform
import UserNotifications

/// Scriptable `NotificationPermissionManaging`.
@MainActor
@Observable
public final class FakeNotificationPermissionManager: NotificationPermissionManaging {
  public var authorizationStatus: UNAuthorizationStatus
  public var grantsAuthorization: Bool

  public init(authorizationStatus: UNAuthorizationStatus = .notDetermined, grantsAuthorization: Bool = true) {
    self.authorizationStatus = authorizationStatus
    self.grantsAuthorization = grantsAuthorization
  }

  public func refreshStatus() async {}

  public func requestAuthorization() async -> Bool {
    authorizationStatus = grantsAuthorization ? .authorized : .denied
    return grantsAuthorization
  }
}

/// Scriptable `WatchConnectivityManaging`.
@MainActor
@Observable
public final class FakeWatchConnectivityManager: WatchConnectivityManaging {
  public var isWatchReachable: Bool
  public var lastSyncedSession: Date?

  public init(isWatchReachable: Bool = false) {
    self.isWatchReachable = isWatchReachable
  }

  public func checkReachability() {}
}
