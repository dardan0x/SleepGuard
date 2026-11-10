import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Push-notification authorization. Fake: `FakeNotificationPermissionManager`.
@MainActor
public protocol NotificationPermissionManaging: AnyObject, Observable {
  var authorizationStatus: UNAuthorizationStatus { get }
  func refreshStatus() async
  @discardableResult
  func requestAuthorization() async -> Bool
}

/// Firebase-free wrapper around the system notification authorization state.
/// Feature packages use this to drive the soft-ask UI; the app-target
/// `AppDelegate` handles the Firebase Messaging / APNs token plumbing.
@MainActor
@Observable
public final class NotificationPermissionManager: NotificationPermissionManaging {
  public static let shared = NotificationPermissionManager()

  public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

  public init() {}

  public func refreshStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    authorizationStatus = settings.authorizationStatus
  }

  /// Requests system permission. On grant, registers for remote notifications
  /// so APNs/FCM tokens are delivered to the AppDelegate.
  @discardableResult
  public func requestAuthorization() async -> Bool {
    let granted = await (try? UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    await refreshStatus()
    #if canImport(UIKit)
    if granted {
      UIApplication.shared.registerForRemoteNotifications()
    }
    #endif
    return granted
  }
}
