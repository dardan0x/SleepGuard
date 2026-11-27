public import Foundation
public import Observation
public import SleepCore
import SleepSettings

// NOTE: These properties use manual access/withMutation because @Observable only
// auto-instruments stored properties. Computed properties backed by UserDefaults
// silently fail to emit change notifications without explicit registrar calls.
// This was surfaced during iOS Simulator testing but applies to all targets.

@MainActor
@Observable
public final class UserPreferences: UserPreferencesStoring {
  public static let shared = UserPreferences()

  /// This app's own settings (appearance, clip length, …).
  private let defaults: UserDefaults
  /// The settings every SleepGuard app has: keys, defaults and validity are
  /// SleepGuardShared's `PreferencesDefaults`, the same code as
  /// SleepGuardUIKitWay's store. These properties only add observation.
  private let settings: PreferencesDefaults

  public var hasCompletedOnboarding: Bool {
    get {
      access(keyPath: \.hasCompletedOnboarding)
      return settings.hasCompletedOnboarding
    }
    set {
      withMutation(keyPath: \.hasCompletedOnboarding) {
        settings.hasCompletedOnboarding = newValue
      }
    }
  }

  public var detectionSensitivity: DetectionSensitivity {
    get {
      access(keyPath: \.detectionSensitivity)
      return settings.sensitivity
    }
    set {
      withMutation(keyPath: \.detectionSensitivity) {
        settings.sensitivity = newValue
      }
    }
  }

  public var saveAudioClips: Bool {
    get {
      access(keyPath: \.saveAudioClips)
      return defaults.bool(forKey: "saveAudioClips")
    }
    set {
      withMutation(keyPath: \.saveAudioClips) {
        defaults.set(newValue, forKey: "saveAudioClips")
      }
    }
  }

  public var preserveRawAudio: Bool {
    get {
      access(keyPath: \.preserveRawAudio)
      return settings.preserveRawAudio
    }
    set {
      withMutation(keyPath: \.preserveRawAudio) {
        settings.preserveRawAudio = newValue
      }
    }
  }

  public var appearance: AppearanceSetting {
    get {
      access(keyPath: \.appearance)
      let raw = defaults.string(forKey: "appearance") ?? "dark"
      return AppearanceSetting(rawValue: raw) ?? .dark
    }
    set {
      withMutation(keyPath: \.appearance) {
        defaults.set(newValue.rawValue, forKey: "appearance")
      }
    }
  }

  public var presentRecordingAfterOnboarding: Bool {
    get {
      access(keyPath: \.presentRecordingAfterOnboarding)
      return defaults.bool(forKey: "presentRecordingAfterOnboarding")
    }
    set {
      withMutation(keyPath: \.presentRecordingAfterOnboarding) {
        defaults.set(newValue, forKey: "presentRecordingAfterOnboarding")
      }
    }
  }

  public var maxClipLength: TimeInterval {
    get {
      access(keyPath: \.maxClipLength)
      let raw = defaults.double(forKey: "maxClipLength")
      return raw > 0 ? raw : 30.0
    }
    set {
      withMutation(keyPath: \.maxClipLength) {
        defaults.set(newValue, forKey: "maxClipLength")
      }
    }
  }

  public var syncToHealthKit: Bool {
    get {
      access(keyPath: \.syncToHealthKit)
      return settings.syncToHealth
    }
    set {
      withMutation(keyPath: \.syncToHealthKit) {
        settings.syncToHealth = newValue
      }
    }
  }

  public var hasExplicitlySetSyncToHealthKit: Bool {
    get {
      access(keyPath: \.hasExplicitlySetSyncToHealthKit)
      return defaults.bool(forKey: "hasExplicitlySetSyncToHealthKit")
    }
    set {
      withMutation(keyPath: \.hasExplicitlySetSyncToHealthKit) {
        defaults.set(newValue, forKey: "hasExplicitlySetSyncToHealthKit")
      }
    }
  }

  public var detectSleepTalking: Bool {
    get {
      access(keyPath: \.detectSleepTalking)
      return settings.detectSleepTalking
    }
    set {
      withMutation(keyPath: \.detectSleepTalking) {
        settings.detectSleepTalking = newValue
      }
    }
  }

  public var enhancedSleepTracking: Bool {
    get {
      access(keyPath: \.enhancedSleepTracking)
      return defaults.bool(forKey: "enhancedSleepTracking")
    }
    set {
      withMutation(keyPath: \.enhancedSleepTracking) {
        defaults.set(newValue, forKey: "enhancedSleepTracking")
      }
    }
  }

  /// When true, snore-event clips play through a band-pass + per-clip
  /// peak normalization on the event player. Defaults to true so new
  /// installs hear the enhancement immediately.
  public var enhancedAudioPlayback: Bool {
    get {
      access(keyPath: \.enhancedAudioPlayback)
      // Default true on first access (when key has never been written).
      if defaults.object(forKey: "enhancedAudioPlayback") == nil { return true }
      return defaults.bool(forKey: "enhancedAudioPlayback")
    }
    set {
      withMutation(keyPath: \.enhancedAudioPlayback) {
        defaults.set(newValue, forKey: "enhancedAudioPlayback")
      }
    }
  }

  public var hasExplicitlySetEnhancedSleepTracking: Bool {
    get {
      access(keyPath: \.hasExplicitlySetEnhancedSleepTracking)
      return defaults.bool(forKey: "hasExplicitlySetEnhancedSleepTracking")
    }
    set {
      withMutation(keyPath: \.hasExplicitlySetEnhancedSleepTracking) {
        defaults.set(newValue, forKey: "hasExplicitlySetEnhancedSleepTracking")
      }
    }
  }

  public var recordingDelayMinutes: Int {
    get {
      access(keyPath: \.recordingDelayMinutes)
      return settings.recordingDelayMinutes
    }
    set {
      withMutation(keyPath: \.recordingDelayMinutes) {
        settings.recordingDelayMinutes = newValue
      }
    }
  }

  /// SleepCore's (same cases and raw values, so stored settings read the same).
  public typealias DetectionSensitivity = SleepCore.DetectionSensitivity

  public enum AppearanceSetting: String, CaseIterable, Sendable {
    case light
    case dark
    case system
  }

  public var snoreInterrupterMode: SnoreInterrupterMode {
    get {
      access(keyPath: \.snoreInterrupterMode)
      return settings.interrupterMode
    }
    set {
      withMutation(keyPath: \.snoreInterrupterMode) {
        settings.interrupterMode = newValue
      }
    }
  }

  public var selectedMelodyID: Int {
    get {
      access(keyPath: \.selectedMelodyID)
      return settings.melodyID
    }
    set {
      withMutation(keyPath: \.selectedMelodyID) {
        settings.melodyID = newValue
      }
    }
  }

  public var limitStorageEnabled: Bool {
    get {
      access(keyPath: \.limitStorageEnabled)
      return settings.limitStorage
    }
    set {
      withMutation(keyPath: \.limitStorageEnabled) {
        settings.limitStorage = newValue
      }
    }
  }

  public var storageLimitMB: Int {
    get {
      access(keyPath: \.storageLimitMB)
      return settings.storageLimitMB
    }
    set {
      withMutation(keyPath: \.storageLimitMB) {
        settings.storageLimitMB = newValue
      }
    }
  }

  public var limitDaysEnabled: Bool {
    get {
      access(keyPath: \.limitDaysEnabled)
      return settings.limitDays
    }
    set {
      withMutation(keyPath: \.limitDaysEnabled) {
        settings.limitDays = newValue
      }
    }
  }

  public var maxDays: Int {
    get {
      access(keyPath: \.maxDays)
      return settings.maxDays
    }
    set {
      withMutation(keyPath: \.maxDays) {
        settings.maxDays = newValue
      }
    }
  }

  // MARK: - Personalization & Sleep Briefing

  public var lastBriefingShownDate: Date? {
    get {
      access(keyPath: \.lastBriefingShownDate)
      return settings.lastBriefingShown
    }
    set {
      withMutation(keyPath: \.lastBriefingShownDate) {
        settings.lastBriefingShown = newValue
      }
    }
  }

  public var hasCompletedProfile: Bool {
    get {
      access(keyPath: \.hasCompletedProfile)
      return settings.hasCompletedProfile
    }
    set {
      withMutation(keyPath: \.hasCompletedProfile) {
        settings.hasCompletedProfile = newValue
      }
    }
  }

  public var profilePromptDismissCount: Int {
    get {
      access(keyPath: \.profilePromptDismissCount)
      return settings.profilePromptDismissCount
    }
    set {
      withMutation(keyPath: \.profilePromptDismissCount) {
        settings.profilePromptDismissCount = newValue
      }
    }
  }

  public var briefingEnabled: Bool {
    get {
      access(keyPath: \.briefingEnabled)
      return settings.briefingEnabled
    }
    set {
      withMutation(keyPath: \.briefingEnabled) {
        settings.briefingEnabled = newValue
      }
    }
  }

  // MARK: - Notifications soft-ask

  /// Number of app launches, used to gate the notification soft-ask.
  public var appOpenCount: Int {
    get {
      access(keyPath: \.appOpenCount)
      return defaults.integer(forKey: "appOpenCount")
    }
    set {
      withMutation(keyPath: \.appOpenCount) {
        defaults.set(newValue, forKey: "appOpenCount")
      }
    }
  }

  /// True once the user has acted on (or dismissed) the notification soft-ask.
  public var notificationSoftAskDismissed: Bool {
    get {
      access(keyPath: \.notificationSoftAskDismissed)
      return defaults.bool(forKey: "notificationSoftAskDismissed")
    }
    set {
      withMutation(keyPath: \.notificationSoftAskDismissed) {
        defaults.set(newValue, forKey: "notificationSoftAskDismissed")
      }
    }
  }

  /// SleepCore's mode (same raw values, so stored choices read back).
  public typealias SnoreInterrupterMode = SleepCore.SnoreInterrupterMode

  /// `nil`: the app's standard defaults; tests pass a suite of their own.
  public init(suiteName: String? = nil) {
    defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    settings = PreferencesDefaults(suiteName: suiteName)
  }
}
