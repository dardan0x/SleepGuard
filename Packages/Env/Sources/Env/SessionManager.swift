import Foundation
import Observation
import Models
import AudioEngine

@MainActor
@Observable
public final class SessionManager {
  public static let shared = SessionManager()

  public var currentSession: SleepSession?
  public var isRecording = false
  public var completedSession: SleepSession?

  /// Real-time audio level for UI observation
  public var currentDB: Float = -160.0
  public var currentSnoringState: SnoringState = .none

  private let audioRecorder = AudioRecorder.shared
  private let snoreDetector = SnoreDetector.shared

  // MARK: - Event tracking state

  private var activeEventStart: Date?
  private var activeEventDBSum: Double = 0
  private var activeEventDBCount: Int = 0
  private var activeEventPeakDB: Double = 0

  // MARK: - Session aggregate state

  private var totalDBSum: Double = 0
  private var totalDBCount: Int = 0
  private var sessionSnoringDuration: TimeInterval = 0
  private var lastUpdateTime: Date?

  private init() {}

  // MARK: - Lifecycle

  public func startSession() throws {
    resetTrackingState()

    let session = SleepSession(startDate: Date())
    currentSession = session

    try audioRecorder.startRecording()
    isRecording = true
    currentDB = -160.0
    currentSnoringState = .none
  }

  public func stopSession() -> SleepSession? {
    audioRecorder.stopRecording()
    isRecording = false

    // Finalize any in-progress snore event
    if currentSnoringState != .none {
      finalizeActiveEvent(intensity: intensity(from: currentSnoringState))
    }

    guard let session = currentSession else { return nil }

    let now = Date()
    let totalDuration = now.timeIntervalSince(session.startDate)

    session.endDate = now
    session.totalDuration = totalDuration
    session.snoringDuration = sessionSnoringDuration
    session.snoringPercentage = totalDuration > 0 ? (sessionSnoringDuration / totalDuration) * 100 : 0
    session.eventsCount = session.events?.count ?? 0
    session.eventsPerHour = totalDuration > 0 ? Double(session.eventsCount) / (totalDuration / 3600) : 0
    session.averageDB = totalDBCount > 0 ? totalDBSum / Double(totalDBCount) : 0
    session.sleepScore = computeSleepScore(session: session)

    let result = session
    completedSession = result
    currentSession = nil
    resetTrackingState()
    return result
  }

  // MARK: - Real-time audio processing

  /// Call this from the view when `audioRecorder.currentDB` changes.
  public func processAudioLevel(db: Float) {
    guard isRecording, let session = currentSession else { return }

    let now = Date()
    let timeDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
    lastUpdateTime = now

    currentDB = db

    // Update running aggregates
    totalDBSum += Double(db)
    totalDBCount += 1
    if Double(db) > session.peakDB {
      session.peakDB = Double(db)
    }

    // Classify snoring state
    let state = snoreDetector.classify(db: db)

    // Accumulate snoring duration
    if state != .none {
      sessionSnoringDuration += timeDelta
    }

    // Handle state transitions
    if state != .none && currentSnoringState == .none {
      // Snoring started
      activeEventStart = now
      activeEventDBSum = Double(db)
      activeEventDBCount = 1
      activeEventPeakDB = Double(db)
    } else if state != .none && currentSnoringState != .none {
      // Snoring continues
      activeEventDBSum += Double(db)
      activeEventDBCount += 1
      if Double(db) > activeEventPeakDB {
        activeEventPeakDB = Double(db)
      }
    } else if state == .none && currentSnoringState != .none {
      // Snoring ended
      finalizeActiveEvent(intensity: intensity(from: currentSnoringState))
    }

    currentSnoringState = state

    // Update session in-memory stats for real-time UI
    session.snoringDuration = sessionSnoringDuration
    session.totalDuration = now.timeIntervalSince(session.startDate)
    if totalDBCount > 0 {
      session.averageDB = totalDBSum / Double(totalDBCount)
    }
    session.eventsCount = session.events?.count ?? 0
    if session.totalDuration > 0 {
      session.snoringPercentage = (sessionSnoringDuration / session.totalDuration) * 100
    }
  }

  // MARK: - Sleep score

  public func computeSleepScore(session: SleepSession) -> Int {
    let snoringPenalty = min(Int(session.snoringPercentage * 0.5), 30)
    let eventsPenalty = min(Int(session.eventsPerHour * 2), 30)
    let score = max(0, 100 - snoringPenalty - eventsPenalty)
    return score
  }

  // MARK: - Private helpers

  private func resetTrackingState() {
    activeEventStart = nil
    activeEventDBSum = 0
    activeEventDBCount = 0
    activeEventPeakDB = 0
    totalDBSum = 0
    totalDBCount = 0
    sessionSnoringDuration = 0
    lastUpdateTime = nil
  }

  private func finalizeActiveEvent(intensity: SnoreIntensity) {
    guard let startTime = activeEventStart, let session = currentSession else { return }
    let duration = Date().timeIntervalSince(startTime)
    guard duration >= 0.5 else {
      // Too brief — discard
      activeEventStart = nil
      activeEventDBSum = 0
      activeEventDBCount = 0
      activeEventPeakDB = 0
      return
    }

    let event = SnoreEvent(
      timestamp: startTime,
      duration: duration,
      intensity: intensity,
      averageDB: activeEventDBCount > 0 ? activeEventDBSum / Double(activeEventDBCount) : 0,
      peakDB: activeEventPeakDB
    )
    event.session = session

    if session.events == nil {
      session.events = []
    }
    session.events?.append(event)

    activeEventStart = nil
    activeEventDBSum = 0
    activeEventDBCount = 0
    activeEventPeakDB = 0
  }

  private func intensity(from state: SnoringState) -> SnoreIntensity {
    switch state {
    case .quiet: return .quiet
    case .light: return .light
    case .loud: return .loud
    case .none: return .quiet
    }
  }
}
