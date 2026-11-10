import AudioEngine
import Env
import Foundation
import Models
import Observation

/// Scriptable `SessionManaging`: set the state a view should render.
@MainActor
@Observable
public final class FakeSessionManager: SessionManaging {
  public var currentSession: SleepSession?
  public var isRecording = false
  public var completedSession: SleepSession?
  public var isProcessingSession = false
  public var isLiveSessionVisible = false
  public var currentDB: Float = -60
  public var currentDetectionState: DetectionState = .none
  public var currentSpeechDetected = false
  public var eventsCount = 0
  public private(set) var startCount = 0
  public private(set) var processedLevels: [Float] = []

  public init() {}

  public func startSession() throws {
    startCount += 1
    isRecording = true
  }

  public func stopSession() async -> SleepSession? {
    isRecording = false
    return currentSession
  }

  public func discardCompletedSession() { completedSession = nil }

  public func stopAndDiscardSession() {
    isRecording = false
    currentSession = nil
  }

  public func forceSaveDueToLowBattery() { isRecording = false }

  public func processAudioLevel(db: Float) { processedLevels.append(db) }

  public func processAudioLevel(db: Float, peakDB _: Float?, spectralScore _: Float, snoreConfidence _: Float, speechConfidence _: Float) {
    processedLevels.append(db)
  }
}

/// Scriptable `RecordingDelayManaging`.
@MainActor
@Observable
public final class FakeRecordingDelayManager: RecordingDelayManaging {
  public var isActive = false
  public var targetDate: Date?
  public var currentRemainingSeconds = 0
  public var remainingTimeString: String {
    String(format: "%02d:%02d", currentRemainingSeconds / 60, currentRemainingSeconds % 60)
  }

  public init() {}

  public func startDelay(minutes: Int) {
    isActive = true
    currentRemainingSeconds = minutes * 60
    targetDate = Date().addingTimeInterval(TimeInterval(currentRemainingSeconds))
  }

  public func cancel() {
    isActive = false
    targetDate = nil
  }

  public func finish() { cancel() }
  public func checkIfComplete() -> Bool { isActive && currentRemainingSeconds <= 0 }
}

/// Scriptable `SnoreInterrupterPlaying`; never plays audio.
@MainActor
@Observable
public final class FakeSnoreInterrupterPlayer: SnoreInterrupterPlaying {
  public var isPlaying = false
  public var currentMelodyName: String?
  public var isMutedForSession = false
  public private(set) var playRequests = 0

  public init() {}

  public func playIfNeeded() {
    playRequests += 1
    if !isMutedForSession { isPlaying = true }
  }

  public func stop() { isPlaying = false }
  public func muteForSession() { isMutedForSession = true }
  public func resetSessionMute() { isMutedForSession = false }
}

/// Scriptable `TabCoordinating`.
@MainActor
@Observable
public final class FakeTabCoordinator: TabCoordinating {
  public var selectedTab: AppTab
  public var resetSignal: TabResetSignal?
  public var pendingDeepLink: WidgetDeepLink?

  public init(selectedTab: AppTab = .statistics) {
    self.selectedTab = selectedTab
  }

  public func selectTab(_ tab: AppTab) {
    if selectedTab == tab {
      resetSignal = TabResetSignal(tab: tab)
    } else {
      selectedTab = tab
    }
  }

  public func open(_ link: WidgetDeepLink) {
    selectedTab = .statistics
    pendingDeepLink = link
  }
}
