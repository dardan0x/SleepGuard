import AudioEngine
import AVFoundation
import Env
import Foundation
import Observation
import SoundAnalysis
import UserNotifications

/// Scriptable `AudioRecording`; never opens the microphone.
@MainActor
@Observable
public final class FakeAudioRecorder: AudioRecording {
  public var isRecording = false
  public var isPaused = false
  public var isWarmedUp = false
  public var currentDB: Float = -160
  public var currentPeakDB: Float = -160
  public var spectralScore: Float = 0
  public var hasPermission: Bool
  public var isWritingToFile = false
  public private(set) var currentEventID: UUID?

  public init(hasPermission: Bool = true) {
    self.hasPermission = hasPermission
  }

  public func checkPermission() {}
  public func requestPermission() async -> Bool { hasPermission }
  public func startRecording(audioFileURL _: URL?) throws { isRecording = true }
  public func pauseRecording() { isPaused = true }
  public func resumeRecording() throws { isPaused = false }

  public func startEventFile(eventID: UUID, url _: URL) throws {
    currentEventID = eventID
    isWritingToFile = true
  }

  public func finalizeEventFile() -> URL? {
    currentEventID = nil
    isWritingToFile = false
    return nil
  }

  public func stopRecording() { isRecording = false }
  public func startWarmup() throws { isWarmedUp = true }
  public func stopWarmup() { isWarmedUp = false }
}

/// Scriptable `SoundAnalysisDetecting`: set the confidences directly.
@MainActor
@Observable
public final class FakeSoundAnalysisDetector: SoundAnalysisDetecting {
  public var snoreConfidence: Float = 0
  public var speechConfidence: Float = 0
  public var isSnoringClassAvailable = true

  public init() {}

  public func startAnalyzing(format _: AVAudioFormat) -> SNAudioStreamAnalyzer? { nil }
  public func stopAnalyzing() {}
}

/// Scriptable `NotificationPermissionManaging`.
@MainActor
@Observable
public final class FakeNotificationPermissionManager: NotificationPermissionManaging {
  public var authorizationStatus: UNAuthorizationStatus
  public var grantsAuthorization: Bool

  public init(authorizationStatus: UNAuthorizationStatus = .notDetermined, grantsAuthorization: Bool = true) {
    self.authorizationStatus = authorizationStatus
    self.grantsAuthorization = grantsAuthorization
  }

  public func refreshStatus() async {}

  public func requestAuthorization() async -> Bool {
    authorizationStatus = grantsAuthorization ? .authorized : .denied
    return grantsAuthorization
  }
}

/// Scriptable `WatchConnectivityManaging`.
@MainActor
@Observable
public final class FakeWatchConnectivityManager: WatchConnectivityManaging {
  public var isWatchReachable: Bool
  public var lastSyncedSession: Date?

  public init(isWatchReachable: Bool = false) {
    self.isWatchReachable = isWatchReachable
  }

  public func checkReachability() {}
}
