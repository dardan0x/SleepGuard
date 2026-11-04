import Foundation
import Observation

// NOTE: These properties use manual access/withMutation because @Observable only
// auto-instruments stored properties. Computed properties backed by UserDefaults
// silently fail to emit change notifications without explicit registrar calls.
// This was surfaced during iOS Simulator testing but applies to all targets.

@MainActor
@Observable
public final class UserPreferences {
  public static let shared = UserPreferences()

  private let defaults = UserDefaults.standard

  public var hasCompletedOnboarding: Bool {
    get {
      access(keyPath: \.hasCompletedOnboarding)
      return defaults.bool(forKey: "hasCompletedOnboarding")
    }
    set {
      withMutation(keyPath: \.hasCompletedOnboarding) {
        defaults.set(newValue, forKey: "hasCompletedOnboarding")
      }
    }
  }

  public var detectionSensitivity: DetectionSensitivity {
    get {
      access(keyPath: \.detectionSensitivity)
      let raw = defaults.string(forKey: "detectionSensitivity") ?? "medium"
      return DetectionSensitivity(rawValue: raw) ?? .medium
    }
    set {
      withMutation(keyPath: \.detectionSensitivity) {
        defaults.set(newValue.rawValue, forKey: "detectionSensitivity")
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
      return defaults.bool(forKey: "preserveRawAudio")
    }
    set {
      withMutation(keyPath: \.preserveRawAudio) {
        defaults.set(newValue, forKey: "preserveRawAudio")
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
      return defaults.bool(forKey: "syncToHealthKit")
    }
    set {
      withMutation(keyPath: \.syncToHealthKit) {
        defaults.set(newValue, forKey: "syncToHealthKit")
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
      return defaults.bool(forKey: "detectSleepTalking")
    }
    set {
      withMutation(keyPath: \.detectSleepTalking) {
        defaults.set(newValue, forKey: "detectSleepTalking")
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
      let raw = defaults.integer(forKey: "recordingDelayMinutes")
      return [0, 15, 30, 45, 60].contains(raw) ? raw : 0
    }
    set {
      withMutation(keyPath: \.recordingDelayMinutes) {
        defaults.set(newValue, forKey: "recordingDelayMinutes")
      }
    }
  }

  public enum DetectionSensitivity: String, CaseIterable, Sendable {
    case low
    case medium
    case high
  }

  public enum AppearanceSetting: String, CaseIterable, Sendable {
    case light
    case dark
    case system
  }

  public var snoreInterrupterMode: SnoreInterrupterMode {
    get {
      access(keyPath: \.snoreInterrupterMode)
      let raw = defaults.string(forKey: "soothingMelodyMode") ?? "never"
      return SnoreInterrupterMode(rawValue: raw) ?? .never
    }
    set {
      withMutation(keyPath: \.snoreInterrupterMode) {
        defaults.set(newValue.rawValue, forKey: "soothingMelodyMode")
      }
    }
  }

  public var selectedMelodyID: Int {
    get {
      access(keyPath: \.selectedMelodyID)
      let raw = defaults.integer(forKey: "selectedMelodyID")
      return raw > 0 ? raw : 6
    }
    set {
      withMutation(keyPath: \.selectedMelodyID) {
        defaults.set(newValue, forKey: "selectedMelodyID")
      }
    }
  }

  public var limitStorageEnabled: Bool {
    get {
      access(keyPath: \.limitStorageEnabled)
      if defaults.object(forKey: "limitStorageEnabled") == nil { return true }
      return defaults.bool(forKey: "limitStorageEnabled")
    }
    set {
      withMutation(keyPath: \.limitStorageEnabled) {
        defaults.set(newValue, forKey: "limitStorageEnabled")
      }
    }
  }

  public var storageLimitMB: Int {
    get {
      access(keyPath: \.storageLimitMB)
      let raw = defaults.integer(forKey: "storageLimitMB")
      return raw > 0 ? raw : 500
    }
    set {
      withMutation(keyPath: \.storageLimitMB) {
        defaults.set(newValue, forKey: "storageLimitMB")
      }
    }
  }

  public var limitDaysEnabled: Bool {
    get {
      access(keyPath: \.limitDaysEnabled)
      if defaults.object(forKey: "limitDaysEnabled") == nil { return true }
      return defaults.bool(forKey: "limitDaysEnabled")
    }
    set {
      withMutation(keyPath: \.limitDaysEnabled) {
        defaults.set(newValue, forKey: "limitDaysEnabled")
      }
    }
  }

  public var maxDays: Int {
    get {
      access(keyPath: \.maxDays)
      let raw = defaults.integer(forKey: "maxDays")
      return raw > 0 ? raw : 30
    }
    set {
      withMutation(keyPath: \.maxDays) {
        defaults.set(newValue, forKey: "maxDays")
      }
    }
  }

  // MARK: - Personalization & Sleep Briefing

  public var lastBriefingShownDate: Date? {
    get {
      access(keyPath: \.lastBriefingShownDate)
      return defaults.object(forKey: "lastBriefingShownDate") as? Date
    }
    set {
      withMutation(keyPath: \.lastBriefingShownDate) {
        if let newValue {
          defaults.set(newValue, forKey: "lastBriefingShownDate")
        } else {
          defaults.removeObject(forKey: "lastBriefingShownDate")
        }
      }
    }
  }

  public var hasCompletedProfile: Bool {
    get {
      access(keyPath: \.hasCompletedProfile)
      return defaults.bool(forKey: "hasCompletedProfile")
    }
    set {
      withMutation(keyPath: \.hasCompletedProfile) {
        defaults.set(newValue, forKey: "hasCompletedProfile")
      }
    }
  }

  public var profilePromptDismissCount: Int {
    get {
      access(keyPath: \.profilePromptDismissCount)
      return defaults.integer(forKey: "profilePromptDismissCount")
    }
    set {
      withMutation(keyPath: \.profilePromptDismissCount) {
        defaults.set(newValue, forKey: "profilePromptDismissCount")
      }
    }
  }

  public var briefingEnabled: Bool {
    get {
      access(keyPath: \.briefingEnabled)
      if defaults.object(forKey: "briefingEnabled") == nil { return true }
      return defaults.bool(forKey: "briefingEnabled")
    }
    set {
      withMutation(keyPath: \.briefingEnabled) {
        defaults.set(newValue, forKey: "briefingEnabled")
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

  public enum SnoreInterrupterMode: String, CaseIterable, Sendable {
    case never
    case always
    case fiveSeconds
    case fifteenSeconds
    case thirtySeconds
    case sixtySeconds

    public var displayLabel: String {
      switch self {
      case .never: "Never"
      case .always: "Always"
      case .fiveSeconds: "5 seconds"
      case .fifteenSeconds: "15 seconds"
      case .thirtySeconds: "30 seconds"
      case .sixtySeconds: "60 seconds"
      }
    }
  }

  private init() {}
}
