import Foundation
import UserNotifications

/// Push-notification authorization. Fake: `FakeNotificationPermissionManager`.
@MainActor
public protocol NotificationPermissionManaging: AnyObject, Observable {
  var authorizationStatus: UNAuthorizationStatus { get }
  func refreshStatus() async
  @discardableResult
  func requestAuthorization() async -> Bool
}
