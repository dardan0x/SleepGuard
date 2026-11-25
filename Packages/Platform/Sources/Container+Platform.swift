import FactoryKit

/// Platform's registrations. Fakes in PlatformTestSupport.
public extension Container {
  @MainActor var hapticManager: Factory<any HapticFeedbackProviding> { self { HapticManager.shared }.singleton }
  @MainActor var notificationPermissionManager: Factory<any NotificationPermissionManaging> {
    self { NotificationPermissionManager.shared }.singleton
  }

  @MainActor var watchConnectivityManager: Factory<any WatchConnectivityManaging> {
    self { WatchConnectivityManager.shared }.singleton
  }
}
