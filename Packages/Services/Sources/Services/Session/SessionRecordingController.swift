import AudioEngine
import Config
import FactoryKit
import Foundation
import Models
import os
import SleepCore
import UIKit

/// Recording lifecycle for a sleep session: starts/stops the audio engine,
/// owns the session object and its persisted files, turns per-buffer readings
/// into SleepCore's fixed 20 Hz samples (`SampleDecimator`) for
/// `RealtimeDetectionTracker`, reports capture interruptions, and handles
/// low-battery force save. Detection state itself lives in the tracker.
@MainActor
@Observable
final class SessionRecordingController {
  private(set) var currentSession: SleepSession?
  var completedSession: SleepSession?
  private(set) var isRecording = false
  private(set) var isProcessingSession = false
  var isLiveSessionVisible = false

  private let audioRecorder: any AudioRecording
  private let snoreInterrupterPlayer: any SnoreInterrupterPlaying
  private let preferences: any UserPreferencesStoring
  private let pendingSessionStore: any PendingSessionStoring
  private let checkpointStore: any SessionCheckpointStoring
  private let rawLogWriter: any SessionRawLogWriting
  private var detection: RealtimeDetectionTracker?
  /// `false` in tests that script every sample themselves (F22-T10).
  private let runsProcessingLoop: Bool

  /// Remote flags are frozen from start to stop, so a night runs under one set.
  private let appConfig: any AppConfigProviding
  /// What detection reads per sample.
  private struct Reading {
    let db: Float
    let peakDB: Float
    let spectralScore: Float
    let snoreConfidence: Float
    let speechConfidence: Float
  }

  /// Per-buffer readings to 20 Hz samples (the same samples on every app).
  private var decimator = SampleDecimator<Reading>()
  /// Housekeeping while recording: battery and the periodic checkpoint.
  private var processingTask: Task<Void, Never>?
  private var batteryCheckCounter = 0
  private var checkpointCounter = 0
  private var thermalObserver: (any NSObjectProtocol)?
  /// Instruments interval for the running session (Points of Interest).
  private var sessionSignpost: OSSignpostIntervalState?

  init(
    audioRecorder: any AudioRecording = Container.shared.audioRecorder(),
    snoreInterrupterPlayer: any SnoreInterrupterPlaying = Container.shared.snoreInterrupterPlayer(),
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    pendingSessionStore: any PendingSessionStoring = Container.shared.pendingSessionStore(),
    checkpointStore: any SessionCheckpointStoring = Container.shared.sessionCheckpointStore(),
    rawLogWriter: any SessionRawLogWriting = Container.shared.sessionRawLogWriter(),
    appConfig: any AppConfigProviding = Container.shared.appConfig(),
    runsProcessingLoop: Bool = true)
  {
    self.appConfig = appConfig
    self.runsProcessingLoop = runsProcessingLoop
    self.audioRecorder = audioRecorder
    self.snoreInterrupterPlayer = snoreInterrupterPlayer
    self.preferences = preferences
    self.pendingSessionStore = pendingSessionStore
    self.checkpointStore = checkpointStore
    self.rawLogWriter = rawLogWriter
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
    pendingSessionStore.cleanupIfNeeded()

    let session = SleepSession(startDate: Date())
    session.recordingGaps = []
    currentSession = session
    let sessionAudioFilename = preferences.preserveRawAudio ? RawRecording.audioFileName(for: session.id) : nil
    pendingSessionStore.setPending(sessionID: session.id, sessionAudioFilename: sessionAudioFilename)

    // Apply detection sensitivity thresholds before starting
    detection?.applyDetectionSensitivity()

    // Full-session raw audio is only recorded in debug mode for algorithm
    // testing (it also turns on the spectral score).
    session.audioFileURL = sessionAudioFilename
    try audioRecorder.startRecording(rawAudioFileName: sessionAudioFilename)
    isRecording = true
    appConfig.holdRemoteUpdates()
    sessionSignpost = Log.signposter.beginInterval("Session")
    Log.session.info("Session started")
    detection?.setActive(true)
    detection?.resetDisplayState()

    // Raw classification log is a debug re-processing aid (~65 MB/night of
    // JSON Lines, nothing reads it in production yet), so it is gated behind
    // the same flag as the full raw audio. It's written while recording, so
    // register it for crash cleanup now, not at stop.
    if preferences.preserveRawAudio {
      let prefs = preferences
      let metadata = RawLogMetadata(
        sessionStart: session.startDate,
        detectionSensitivity: prefs.detectionSensitivity.rawValue,
        detectSleepTalking: prefs.detectSleepTalking,
        snoreInterrupterMode: prefs.snoreInterrupterMode.rawValue)
      let sessionID = session.id
      pendingSessionStore.addFile(SessionRawLogWriter.fileName(for: sessionID))
      Task { [rawLogWriter] in
        await rawLogWriter.start(sessionID: sessionID, metadata: metadata)
      }
    }

    // Detection samples come from the tap, through the decimator; this loop
    // only does housekeeping, so it also runs while capture is interrupted.
    decimator.reset()
    audioRecorder.onLevels = { [weak self] time in self?.didReceiveLevels(at: time) }
    audioRecorder.onCaptureInterruption = { [weak self] interrupted, time in
      self?.captureDidChange(interrupted: interrupted, at: time)
    }
    startThermalObservation()
    guard runsProcessingLoop else { return }
    processingTask = Task { @MainActor in
      while !Task.isCancelled {
        self.batteryCheckCounter += 1
        if self.batteryCheckCounter >= 30 {
          self.batteryCheckCounter = 0
          self.checkBatteryLevel()
        }
        // Periodic recovery checkpoint (~every 2 min) so session-level
        // progress and gaps survive a crash even during long stretches
        // without events. Event-driven checkpoints handle the rest.
        self.checkpointCounter += 1
        if self.checkpointCounter >= 120 {
          self.checkpointCounter = 0
          self.detection?.checkpoint()
        }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  private func checkBatteryLevel() {
    #if targetEnvironment(simulator)
    return
    #else
    let level = UIDevice.current.batteryLevel
    guard level >= 0, level <= 0.02 else { return }
    Log.session.notice("Battery level at \(Int(level * 100))% — force saving session")
    forceSaveDueToLowBattery()
    #endif
  }

  /// One tapped buffer's levels and the sound classifier's latest
  /// confidences, as the recorder just published them. Feeds every 20 Hz window that ended.
  private func didReceiveLevels(at time: Date) {
    let reading = Reading(
      db: audioRecorder.currentDB,
      peakDB: audioRecorder.currentPeakDB,
      spectralScore: audioRecorder.spectralScore,
      snoreConfidence: audioRecorder.snoreConfidence,
      speechConfidence: audioRecorder.speechConfidence)
    for sample in decimator.add(reading, at: time) {
      let r = sample.reading
      detection?.processAudioLevel(
        db: r.db, peakDB: r.peakDB, spectralScore: r.spectralScore,
        snoreConfidence: r.snoreConfidence, speechConfidence: r.speechConfidence, at: sample.time)
    }
  }

  /// A call or another app took the microphone, or gave it back. Detection
  /// records the paused span as an interruption gap; sampling restarts fresh.
  private func captureDidChange(interrupted: Bool, at time: Date) {
    Log.session.notice("Capture \(interrupted ? "interrupted" : "resumed", privacy: .public)")
    decimator.reset()
    detection?.captureDidChange(interrupted: interrupted, at: time)
  }

  /// Logs thermal pressure during a night. No response yet (a lower analysis
  /// rate would change detection); the log is what a device profile reads.
  private func startThermalObservation() {
    logThermalState()
    thermalObserver = NotificationCenter.default.addObserver(
      forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main)
    { [weak self] _ in
      MainActor.assumeIsolated { self?.logThermalState() }
    }
  }

  private func stopThermalObservation() {
    thermalObserver.map(NotificationCenter.default.removeObserver)
    thermalObserver = nil
  }

  private func logThermalState() {
    let state = ProcessInfo.processInfo.thermalState
    let name = switch state {
    case .nominal: "nominal"
    case .fair: "fair"
    case .serious: "serious"
    case .critical: "critical"
    @unknown default: "unknown"
    }
    Log.session.notice("Thermal state: \(name, privacy: .public)")
    Log.signposter.emitEvent("Thermal", "\(name, privacy: .public)")
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
    audioRecorder.onLevels = nil
    audioRecorder.onCaptureInterruption = nil
    stopThermalObservation()

    snoreInterrupterPlayer.stop()
    isRecording = false
    appConfig.releaseRemoteUpdates()
    endSessionSignpost(reason: "stopped")
    detection?.setActive(false)

    // Finalize any in-progress events BEFORE stopping the audio engine —
    // see RealtimeDetectionTracker.finishDetection().
    await detection?.finishDetection()

    audioRecorder.stopRecording()

    // Wait for any in-flight per-event compression tasks to finish.
    await detection?.awaitPendingCompression()

    guard let session = currentSession else { return nil }

    let now = Date()

    session.endDate = now
    session.averageDB = detection.map(\.totalAverageDB) ?? session.averageDB
    detection?.syncEventsCount(with: session)

    // In debug mode with raw audio preserved, move the full session file to rawAudioFileURL
    // so event clips remain the primary playback source.
    if preferences.preserveRawAudio,
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
    // Already registered with the pending store at start.
    session.rawLogFileURL = await rawLogWriter.stop()

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
    pendingSessionStore.cleanupIfNeeded()
    checkpointStore.clear()
    completedSession = nil
  }

  /// Stops the current recording and discards the session without presenting the summary.
  /// Used when the user explicitly chooses to stop a session that is below the minimum duration.
  func stopAndDiscardSession() {
    Task { @MainActor in
      processingTask?.cancel()
      processingTask = nil
      audioRecorder.onLevels = nil
      audioRecorder.onCaptureInterruption = nil
      stopThermalObservation()

      snoreInterrupterPlayer.stop()
      isRecording = false
      endSessionSignpost(reason: "discarded")
      detection?.setActive(false)

      // Finalize events BEFORE stopping audio engine so file URLs are
      // captured while currentEventFile still exists.
      await detection?.finishDetection()

      audioRecorder.stopRecording()

      // Wait for any in-flight compression tasks before deleting files.
      await detection?.awaitPendingCompression()

      // The raw log is written while recording (F23-T9): close and delete it.
      await rawLogWriter.discard()

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

      pendingSessionStore.cleanupIfNeeded()
      checkpointStore.clear()
      currentSession = nil
      detection?.reset()
    }
  }

  // MARK: - Private

  private func endSessionSignpost(reason: StaticString) {
    guard let sessionSignpost else { return }
    Log.signposter.endInterval("Session", sessionSignpost, "\(reason)")
    self.sessionSignpost = nil
    Log.session.info("Session \(reason)")
  }
}
