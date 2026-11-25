import AVFoundation
import Config
import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// The values `SettingsView` hands the shared content, and what its taps do.
extension SettingsView {
  var permissions: SettingsPermissions {
    SettingsPermissions(
      microphone: Self.permission(microphone),
      notifications: Self.permission(notifications.authorizationStatus),
      onMicrophone: { requestMicrophone() },
      onNotifications: { requestNotifications() })
  }

  var recording: SettingsRecording {
    #if DEBUG
    let preserveRawAudio: Binding<Bool>? = binding(\.preserveRawAudio)
    #else
    let preserveRawAudio: Binding<Bool>? = nil
    #endif
    return SettingsRecording(
      sensitivity: binding(\.detectionSensitivity),
      sleepTalking: appConfig.isEnabled(.sleepTalkingDetection) ? binding(\.detectSleepTalking) : nil,
      preserveRawAudio: preserveRawAudio)
  }

  var profile: SettingsProfile {
    SettingsProfile(
      onOpen: { routerPath.presentedSheet = .profileEditor },
      briefing: appConfig.isEnabled(.sleepBriefing) ? binding(\.briefingEnabled) : nil)
  }

  var watch: SettingsWatch? {
    guard appConfig.isEnabled(.watchApp) else { return nil }
    return SettingsWatch(
      isReachable: watchConnectivityManager.isWatchReachable,
      enhancedTracking: appConfig.isEnabled(.enhancedSleepTracking)
        ? healthBinding(\.enhancedSleepTracking, explicit: \.hasExplicitlySetEnhancedSleepTracking) : nil)
  }

  var storage: SettingsStorage {
    #if DEBUG
    let onTestCleanup: (() -> Void)? = { runTestCleanup() }
    #else
    let onTestCleanup: (() -> Void)? = nil
    #endif
    return SettingsStorage(
      limitStorage: binding(\.limitStorageEnabled),
      megabytes: Binding(get: { userPreferences.storageLimitMB }, set: { changeStorageLimit($0) }),
      limitDays: binding(\.limitDaysEnabled),
      days: binding(\.maxDays),
      onTestCleanup: onTestCleanup)
  }

  var data: SettingsData {
    #if DEBUG
    let onAddSampleNights: (() -> Void)? = { MockDataGenerator.generate(modelContext: modelContext) }
    #else
    let onAddSampleNights: (() -> Void)? = nil
    #endif
    return SettingsData(
      healthSync: healthBinding(\.syncToHealthKit, explicit: \.hasExplicitlySetSyncToHealthKit),
      onDeleteAll: { showDeleteConfirmation = true },
      onAddSampleNights: onAddSampleNights)
  }

  var about: SettingsAbout {
    SettingsAbout(
      version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
      onRate: { rateApp() })
  }

  // MARK: - Bindings

  private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<any UserPreferencesStoring, Value>) -> Binding<Value> {
    let preferences = userPreferences
    return Binding(get: { preferences[keyPath: keyPath] }, set: { preferences[keyPath: keyPath] = $0 })
  }

  /// Turning on asks HealthKit; the switch stays on only if access is granted.
  private func healthBinding(
    _ keyPath: ReferenceWritableKeyPath<any UserPreferencesStoring, Bool>,
    explicit: ReferenceWritableKeyPath<any UserPreferencesStoring, Bool>) -> Binding<Bool>
  {
    let preferences = userPreferences
    let healthKitSync = healthKitSync
    return Binding(
      get: { preferences[keyPath: keyPath] },
      set: { newValue in
        preferences[keyPath: explicit] = true
        guard newValue else {
          preferences[keyPath: keyPath] = false
          return
        }
        Task { preferences[keyPath: keyPath] = await healthKitSync.requestAuthorization() }
      })
  }

  // MARK: - Actions

  private static func permission(_ status: AVAudioSession.RecordPermission) -> SettingsPermission {
    switch status {
    case .granted: .granted
    case .denied: .denied
    default: .notDetermined
    }
  }

  private static func permission(_ status: UNAuthorizationStatus) -> SettingsPermission {
    switch status {
    case .authorized, .provisional, .ephemeral: .granted
    case .denied: .denied
    default: .notDetermined
    }
  }

  private func requestMicrophone() {
    switch microphone {
    case .undetermined:
      Task {
        let granted = await AVAudioApplication.requestRecordPermission()
        microphone = granted ? .granted : .denied
      }
    case .denied:
      openSystemSettings()
    default:
      break
    }
  }

  private func requestNotifications() {
    switch notifications.authorizationStatus {
    case .notDetermined:
      Task { await notifications.requestAuthorization() }
    case .denied:
      openSystemSettings()
    default:
      break
    }
  }

  private func openSystemSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}
