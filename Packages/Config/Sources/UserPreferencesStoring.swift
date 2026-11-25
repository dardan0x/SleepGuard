import Foundation
import Observation

/// User settings persisted in `UserDefaults`.
/// Live: `UserPreferences`. Tests: `UserPreferences(defaults:)` on an isolated suite.
@MainActor
public protocol UserPreferencesStoring: AnyObject, Observable {
  var hasCompletedOnboarding: Bool { get set }
  var detectionSensitivity: UserPreferences.DetectionSensitivity { get set }
  var saveAudioClips: Bool { get set }
  var preserveRawAudio: Bool { get set }
  var appearance: UserPreferences.AppearanceSetting { get set }
  var presentRecordingAfterOnboarding: Bool { get set }
  var maxClipLength: TimeInterval { get set }
  var syncToHealthKit: Bool { get set }
  var hasExplicitlySetSyncToHealthKit: Bool { get set }
  var detectSleepTalking: Bool { get set }
  var enhancedSleepTracking: Bool { get set }
  var enhancedAudioPlayback: Bool { get set }
  var hasExplicitlySetEnhancedSleepTracking: Bool { get set }
  var recordingDelayMinutes: Int { get set }
  var snoreInterrupterMode: UserPreferences.SnoreInterrupterMode { get set }
  var selectedMelodyID: Int { get set }
  var limitStorageEnabled: Bool { get set }
  var storageLimitMB: Int { get set }
  var limitDaysEnabled: Bool { get set }
  var maxDays: Int { get set }
  var lastBriefingShownDate: Date? { get set }
  var hasCompletedProfile: Bool { get set }
  var profilePromptDismissCount: Int { get set }
  var briefingEnabled: Bool { get set }
  var appOpenCount: Int { get set }
  var notificationSoftAskDismissed: Bool { get set }
}
