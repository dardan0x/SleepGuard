import Env
import FirebaseMessaging
import Models
import os
import UIKit
import UserNotifications

/// Handles APNs registration and Firebase Cloud Messaging. `FirebaseApp.configure()`
/// runs in `SleepGuardApp.init()` before this delegate's `didFinishLaunching`.
final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
  {
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  {
    Messaging.messaging().apnsToken = deviceToken
  }

  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error)
  {
    Log.app.error("APNs registration failed: \(String(describing: error), privacy: .public)")
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    Log.app.debug("FCM token: \(fcmToken ?? "nil")")
    // TODO: forward the token to your backend if you target specific devices.
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  /// Show notifications while the app is in the foreground.
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification) async -> UNNotificationPresentationOptions
  {
    [.banner, .sound, .badge]
  }

  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse) async
  {
    await MainActor.run {
      guard response.notification.request.identifier == RecordingDelayManager.shared.notificationId,
            RecordingDelayManager.shared.isActive else { return }
      RecordingDelayManager.shared.cancel()
      do {
        try SessionManager.shared.startSession()
      } catch {
        Log.session.error("Start from notification failed: \(String(describing: error), privacy: .public)")
      }
    }
  }
}
