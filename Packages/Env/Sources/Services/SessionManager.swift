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
  public var eventsCount: Int = 0

  private let audioRecorder = AudioRecorder.shared
  private let snoreDetector = SnoreDetector.shared

  // MARK: - Event tracking state

  private var activeEventStart: Date?
  private var activeEventIntensity: SnoreIntensity?
  private var activeEventDBSum: Double = 0
  private var activeEventDBCount: Int = 0
  private var activeEventPeakDB: Double = 0
  private var lastSnoringSampleTime: Date?
  private let eventGapThreshold: TimeInterval = 3.0

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
    let audioURL = audioFileURL(for: session.id)
    session.audioFileURL = AudioFileURLResolver.filename(from: audioURL)
    currentSession = session

    try audioRecorder.startRecording(audioFileURL: audioURL)
    isRecording = true
    currentDB = -160.0
    currentSnoringState = .none
    eventsCount = 0
  }

  public func stopSession() async -> SleepSession? {
    audioRecorder.stopRecording()
    isRecording = false

    // Finalize any in-progress snore event (include trailing gap since user stopped mid-session)
    if activeEventStart != nil {
      finalizeActiveEvent(includeGap: true)
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
    eventsCount = session.eventsCount

    // Extract per-event clips and spectral features, then delete full session
    if let events = session.events, !events.isEmpty,
       let sessionURL = AudioFileURLResolver.resolve(session.audioFileURL) {
      let docs = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
      let results = await AudioClipExtractor.extractClips(
        from: sessionURL,
        events: events,
        sessionStart: session.startDate,
        padding: 0.0,
        outputDirectory: docs
      )
      for result in results {
        if let event = events.first(where: { $0.id == result.eventID }) {
          event.audioFileURL = AudioFileURLResolver.filename(from: result.clipURL)
          event.dominantFrequency = result.dominantFrequency
          event.spectralCentroid = result.spectralCentroid
          event.lowFreqRatio = result.lowFreqRatio
        }
      }
      // Only delete full session file if at least one clip was extracted;
      // otherwise keep the original recording as fallback.
      if !results.isEmpty {
        try? FileManager.default.removeItem(at: sessionURL)
        session.audioFileURL = nil
      }
    }

    let result = session
    completedSession = result
    currentSession = nil
    resetTrackingState()
    return result
  }

  public func discardCompletedSession() {
    // Delete event clips
    if let events = completedSession?.events {
      for event in events {
        if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
          try? FileManager.default.removeItem(at: url)
        }
      }
    }
    // Delete legacy full session file if present
    if let url = AudioFileURLResolver.resolve(completedSession?.audioFileURL) {
      try? FileManager.default.removeItem(at: url)
    }
    completedSession = nil
  }

  // MARK: - Real-time audio processing

  /// Call this from the view when `audioRecorder.currentDB` changes.
  public func processAudioLevel(db: Float) {
    processAudioLevel(db: db, spectralScore: 0, snoreConfidence: 0)
  }

  /// Call this from the view when audio features are available.
  public func processAudioLevel(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) {
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

    // Classify snoring state (SoundAnalysis → FFT → thresholds)
    let state = snoreDetector.classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
    #if DEBUG
    if snoreConfidence > 0.1 || spectralScore > 0.1 {
      print("[SessionManager] classify db=\(String(format: "%.1f", db)) spectral=\(String(format: "%.2f", spectralScore)) snoreConf=\(String(format: "%.2f", snoreConfidence)) → \(state)")
    }
    #endif

    // Update display state immediately for UI responsiveness
    currentSnoringState = state

    // Accumulate snoring duration
    if state != .none {
      sessionSnoringDuration += timeDelta
    }

    // Handle event tracking with debounce gap
    if state != .none {
      lastSnoringSampleTime = now
      if activeEventStart == nil {
        // Snoring started
        activeEventStart = now
        activeEventDBSum = Double(db)
        activeEventDBCount = 1
        activeEventPeakDB = Double(db)
        activeEventIntensity = intensity(from: state)
      } else {
        // Snoring continues
        activeEventDBSum += Double(db)
        activeEventDBCount += 1
        if Double(db) > activeEventPeakDB {
          activeEventPeakDB = Double(db)
        }
        // Upgrade intensity if current sample is louder
        let currentIntensity = intensity(from: state)
        if intensityRank(currentIntensity) > intensityRank(activeEventIntensity ?? .quiet) {
          activeEventIntensity = currentIntensity
        }
      }
    } else {
      // Only finalize if we've been silent long enough
      if let lastSnore = lastSnoringSampleTime,
         activeEventStart != nil,
         now.timeIntervalSince(lastSnore) >= eventGapThreshold {
        finalizeActiveEvent()
      }
    }

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
    activeEventIntensity = nil
    activeEventDBSum = 0
    activeEventDBCount = 0
    activeEventPeakDB = 0
    totalDBSum = 0
    totalDBCount = 0
    sessionSnoringDuration = 0
    lastUpdateTime = nil
    lastSnoringSampleTime = nil
  }

  private func finalizeActiveEvent(includeGap: Bool = true) {
    guard let startTime = activeEventStart, let session = currentSession else { return }
    let endTime = includeGap ? Date() : (lastSnoringSampleTime ?? Date())
    let duration = endTime.timeIntervalSince(startTime)
    guard duration >= 0.5 else {
      // Too brief — discard
      activeEventStart = nil
      activeEventIntensity = nil
      activeEventDBSum = 0
      activeEventDBCount = 0
      activeEventPeakDB = 0
      return
    }

    let event = SnoreEvent(
      timestamp: startTime,
      duration: duration,
      intensity: activeEventIntensity ?? .quiet,
      averageDB: activeEventDBCount > 0 ? activeEventDBSum / Double(activeEventDBCount) : 0,
      peakDB: activeEventPeakDB
    )
    event.session = session

    if session.events == nil {
      session.events = []
    }
    session.events?.append(event)
    eventsCount = session.events?.count ?? 0

    activeEventStart = nil
    activeEventIntensity = nil
    activeEventDBSum = 0
    activeEventDBCount = 0
    activeEventPeakDB = 0
  }

  private func audioFileURL(for sessionID: UUID) -> URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("session_\(sessionID.uuidString).caf")
  }

  private func intensity(from state: SnoringState) -> SnoreIntensity {
    switch state {
    case .quiet: return .quiet
    case .light: return .light
    case .loud: return .loud
    case .none: return .quiet
    }
  }

  private func intensityRank(_ intensity: SnoreIntensity) -> Int {
    switch intensity {
    case .quiet: return 0
    case .light: return 1
    case .loud: return 2
    }
  }
}
