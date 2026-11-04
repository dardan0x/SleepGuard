import AudioEngine
import Foundation
import Models
import UIKit

/// Recording lifecycle for a sleep session: starts/stops the audio engine,
/// owns the session object and its persisted files, runs the 50 ms processing
/// loop that feeds `RealtimeDetectionTracker`, and handles low-battery force
/// save. Detection state itself lives in the tracker.
@MainActor
@Observable
final class SessionRecordingController {
  private(set) var currentSession: SleepSession?
  var completedSession: SleepSession?
  private(set) var isRecording = false
  private(set) var isProcessingSession = false
  var isLiveSessionVisible = false

  private let audioRecorder = AudioRecorder.shared
  private let snoreInterrupterPlayer = SnoreInterrupterPlayer.shared
  private var detection: RealtimeDetectionTracker?

  private var processingTask: Task<Void, Never>?
  private var batteryCheckCounter = 0
  private var checkpointCounter = 0

  init() {
    #if !targetEnvironment(simulator)
    UIDevice.current.isBatteryMonitoringEnabled = true
    #endif
  }

  /// Called once by `SessionManager` to wire the detection engine.
  func attach(detection: RealtimeDetectionTracker) {
    self.detection = detection
  }

  // MARK: - Lifecycle

  func startSession() throws {
    detection?.reset()
    processingTask?.cancel()
    snoreInterrupterPlayer.resetSessionMute()
    batteryCheckCounter = 0
    checkpointCounter = 0

    // Clean up any orphaned files from a previous force-closed session.
    PendingSessionStore.shared.cleanupIfNeeded()

    let session = SleepSession(startDate: Date())
    session.recordingGaps = []
    currentSession = session
    let sessionAudioFilename = UserPreferences.shared.preserveRawAudio ? "session_\(session.id.uuidString).caf" : nil
    PendingSessionStore.shared.setPending(sessionID: session.id, sessionAudioFilename: sessionAudioFilename)

    // Apply detection sensitivity thresholds before starting
    detection?.applyDetectionSensitivity()

    // Full-session raw audio is only recorded in debug mode for algorithm testing.
    let audioURL: URL?
    if UserPreferences.shared.preserveRawAudio {
      audioURL = audioFileURL(for: session.id)
      session.audioFileURL = AudioFileURLResolver.filename(from: audioURL!)
    } else {
      audioURL = nil
    }

    try audioRecorder.startRecording(audioFileURL: audioURL)
    isRecording = true
    detection?.setActive(true)
    detection?.resetDisplayState()

    // Raw classification log is a debug re-processing aid (~48 MB/night of
    // JSON for a full night, nothing reads it in production yet), so it is
    // gated behind the same flag as the full raw audio.
    if UserPreferences.shared.preserveRawAudio {
      Task {
        await SessionRawLogWriter.shared.start(sessionID: session.id)
      }
    }

    // Drive processAudioLevel from the recording controller so it survives background.
    processingTask = Task { @MainActor in
      while !Task.isCancelled {
        let saConf = SoundAnalysisDetector.shared.snoreConfidence
        let saSpeechConf = SoundAnalysisDetector.shared.speechConfidence
        self.detection?.processAudioLevel(
          db: self.audioRecorder.currentDB,
          peakDB: self.audioRecorder.currentPeakDB,
          spectralScore: self.audioRecorder.spectralScore,
          snoreConfidence: saConf,
          speechConfidence: saSpeechConf
        )
        self.batteryCheckCounter += 1
        if self.batteryCheckCounter >= 600 {
          self.batteryCheckCounter = 0
          self.checkBatteryLevel()
        }
        // Periodic recovery checkpoint (~every 2 min) so session-level
        // progress and gaps survive a crash even during long stretches
        // without events. Event-driven checkpoints handle the rest.
        self.checkpointCounter += 1
        if self.checkpointCounter >= 2400 {
          self.checkpointCounter = 0
          self.detection?.checkpoint()
        }
        try? await Task.sleep(for: .milliseconds(50))
      }
    }
  }

  private func checkBatteryLevel() {
    #if targetEnvironment(simulator)
    return
    #else
    let level = UIDevice.current.batteryLevel
    guard level >= 0, level <= 0.02 else { return }
    print("[SessionManager] Battery level at \(Int(level * 100))% — force saving session")
    forceSaveDueToLowBattery()
    #endif
  }

  func forceSaveDueToLowBattery() {
    Task { @MainActor in
      guard isRecording else { return }
      currentSession?.terminationReason = "low_battery"
      _ = await stopSession()
    }
  }

  func stopSession() async -> SleepSession? {
    isProcessingSession = true
    defer { isProcessingSession = false }

    processingTask?.cancel()
    processingTask = nil

    snoreInterrupterPlayer.stop()
    isRecording = false
    detection?.setActive(false)

    // Finalize any in-progress events BEFORE stopping the audio engine —
    // see RealtimeDetectionTracker.finalizeActiveEventsIfNeeded().
    detection?.finalizeActiveEventsIfNeeded()

    audioRecorder.stopRecording()

    // Wait for any in-flight per-event compression tasks to finish.
    await detection?.awaitPendingCompression()

    guard let session = currentSession else { return nil }

    let now = Date()

    session.endDate = now
    session.averageDB = detection.map { $0.totalAverageDB } ?? session.averageDB
    detection?.syncEventsCount(with: session)

    // In debug mode with raw audio preserved, move the full session file to rawAudioFileURL
    // so event clips remain the primary playback source.
    if UserPreferences.shared.preserveRawAudio,
       let events = session.events, !events.isEmpty,
       session.rawAudioFileURL == nil,
       session.audioFileURL != nil
    {
      let hasClips = events.contains { $0.audioFileURL != nil }
      if hasClips {
        session.rawAudioFileURL = session.audioFileURL
        session.audioFileURL = nil
      }
    }

    // Save raw classification log
    let logFilename = await SessionRawLogWriter.shared.stop()
    session.rawLogFileURL = logFilename
    if let logFilename {
      PendingSessionStore.shared.addFile(logFilename)
    }

    let result = session
    completedSession = result
    currentSession = nil
    detection?.reset()
    return result
  }

  func discardCompletedSession() {
    // Delete event clips
    if let events = completedSession?.events {
      for event in events {
        if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
          try? FileManager.default.removeItem(at: url)
        }
      }
    }
    // Delete legacy full session file if present (pre-raw-audio sessions)
    if let url = AudioFileURLResolver.resolve(completedSession?.audioFileURL) {
      try? FileManager.default.removeItem(at: url)
    }
    // Delete raw full session archive
    if let url = AudioFileURLResolver.resolve(completedSession?.rawAudioFileURL) {
      try? FileManager.default.removeItem(at: url)
    }
    // Delete raw classification log
    if let url = AudioFileURLResolver.resolve(completedSession?.rawLogFileURL) {
      try? FileManager.default.removeItem(at: url)
    }
    PendingSessionStore.shared.cleanupIfNeeded()
    SessionCheckpointStore.shared.clear()
    completedSession = nil
  }

  /// Stops the current recording and discards the session without presenting the summary.
  /// Used when the user explicitly chooses to stop a session that is below the minimum duration.
  func stopAndDiscardSession() {
    Task { @MainActor in
      processingTask?.cancel()
      processingTask = nil

      snoreInterrupterPlayer.stop()
      isRecording = false
      detection?.setActive(false)

      // Finalize events BEFORE stopping audio engine so file URLs are
      // captured while currentEventFile still exists.
      detection?.finalizeActiveEventsIfNeeded()

      audioRecorder.stopRecording()

      // Wait for any in-flight compression tasks before deleting files.
      await detection?.awaitPendingCompression()

      // Delete the session's audio files and clean up
      if let session = currentSession {
        if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
          try? FileManager.default.removeItem(at: url)
        }
        if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
          try? FileManager.default.removeItem(at: url)
        }
        // Delete per-event files
        if let events = session.events {
          for event in events {
            if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
              try? FileManager.default.removeItem(at: url)
            }
          }
        }
      }

      PendingSessionStore.shared.cleanupIfNeeded()
      SessionCheckpointStore.shared.clear()
      currentSession = nil
      detection?.reset()
    }
  }

  // MARK: - Private

  private func audioFileURL(for sessionID: UUID) -> URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("session_\(sessionID.uuidString).caf")
  }
}
