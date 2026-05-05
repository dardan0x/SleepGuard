import Foundation
import Observation

@MainActor
@Observable
public final class UserPreferences {
  public static let shared = UserPreferences()

  private let defaults = UserDefaults.standard

  public var hasCompletedOnboarding: Bool {
    get { defaults.bool(forKey: "hasCompletedOnboarding") }
    set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
  }

  public var detectionSensitivity: DetectionSensitivity {
    get {
      let raw = defaults.string(forKey: "detectionSensitivity") ?? "medium"
      return DetectionSensitivity(rawValue: raw) ?? .medium
    }
    set { defaults.set(newValue.rawValue, forKey: "detectionSensitivity") }
  }

  public var saveAudioClips: Bool {
    get { defaults.bool(forKey: "saveAudioClips") }
    set { defaults.set(newValue, forKey: "saveAudioClips") }
  }

  public var appearance: AppearanceSetting {
    get {
      let raw = defaults.string(forKey: "appearance") ?? "system"
      return AppearanceSetting(rawValue: raw) ?? .system
    }
    set { defaults.set(newValue.rawValue, forKey: "appearance") }
  }

  public var presentRecordingAfterOnboarding: Bool {
    get { defaults.bool(forKey: "presentRecordingAfterOnboarding") }
    set { defaults.set(newValue, forKey: "presentRecordingAfterOnboarding") }
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

  private init() {}
}
