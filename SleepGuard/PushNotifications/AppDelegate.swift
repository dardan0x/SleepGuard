import UIKit
import UserNotifications
import FirebaseMessaging

/// Handles APNs registration and Firebase Cloud Messaging. `FirebaseApp.configure()`
/// runs in `SleepGuardApp.init()` before this delegate's `didFinishLaunching`.
final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[Push] APNs registration failed: \(error)")
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("[Push] FCM token: \(fcmToken ?? "nil")")
    // TODO: forward the token to your backend if you target specific devices.
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  /// Show notifications while the app is in the foreground.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .sound, .badge]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    // Handle notification taps here if needed.
  }
}
