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

  public var appearance: AppearanceSetting {
    get {
      access(keyPath: \.appearance)
      let raw = defaults.string(forKey: "appearance") ?? "system"
      return AppearanceSetting(rawValue: raw) ?? .system
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

  public var minSnoreDuration: TimeInterval {
    get {
      access(keyPath: \.minSnoreDuration)
      let raw = defaults.double(forKey: "minSnoreDuration")
      return raw > 0 ? raw : 2.0
    }
    set {
      withMutation(keyPath: \.minSnoreDuration) {
        defaults.set(newValue, forKey: "minSnoreDuration")
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

  public var soothingMelodyMode: SoothingMelodyMode {
    get {
      access(keyPath: \.soothingMelodyMode)
      let raw = defaults.string(forKey: "soothingMelodyMode") ?? "never"
      return SoothingMelodyMode(rawValue: raw) ?? .never
    }
    set {
      withMutation(keyPath: \.soothingMelodyMode) {
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

  public enum SoothingMelodyMode: String, CaseIterable, Sendable {
    case never
    case always
    case fiveSeconds
    case fifteenSeconds
    case thirtySeconds
    case sixtySeconds

    public var displayLabel: String {
      switch self {
      case .never: return "Never"
      case .always: return "Always"
      case .fiveSeconds: return "5 seconds"
      case .fifteenSeconds: return "15 seconds"
      case .thirtySeconds: return "30 seconds"
      case .sixtySeconds: return "60 seconds"
      }
    }
  }

  private init() {}
}
