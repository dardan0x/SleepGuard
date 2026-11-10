import AudioEngine
import FactoryKit
import Foundation
import Models
import UIKit

/// Adapter between the 50 ms processing loop and `DetectionStateMachine`.
///
/// Each tick it classifies the sample (`SnoreDetector`, `SpeechDetector`),
/// hands it to the pure state machine, and performs the outputs: event clips,
/// SwiftData events and gaps, the Snore Interrupter, clip compression and
/// recovery checkpoints. The event rules themselves live in the machine
/// (`AudioEngine/Sources/Engine/DetectionStateMachine.swift`).
///
/// Session ownership stays with the controller; the tracker reaches it (and
/// the recording flag) through `recording`.
@MainActor
@Observable
final class RealtimeDetectionTracker {
  /// Real-time state for UI observation
  private(set) var currentDB: Float = -160.0
  private(set) var currentDetectionState: DetectionState = .none
  private(set) var currentSpeechDetected = false
  private(set) var eventsCount = 0

  weak var recording: SessionRecordingController?

  /// Running-session average dB (aggregate of every processed sample).
  var totalAverageDB: Double {
    totalDBCount > 0 ? totalDBSum / Double(totalDBCount) : 0
  }

  private let audioRecorder: any AudioRecording
  private let snoreDetector: SnoreDetector
  private let speechDetector = SpeechDetector.shared
  private let snoreInterrupterPlayer: any SnoreInterrupterPlaying
  private let preferences: any UserPreferencesStoring
  private let pendingSessionStore: any PendingSessionStoring
  private let checkpointStore: any SessionCheckpointStoring
  private let rawLogWriter: any SessionRawLogWriting
  /// Sample timestamps. Tests pass a scripted clock to drive time-based rules.
  private let clock: @MainActor () -> Date

  /// Set by the controller while a session is recording.
  private var isActive = false

  // MARK: - Detection state

  /// Every snore / speech / melody-gap rule. Rebuilt by `reset()`.
  private var machine: DetectionStateMachine

  // MARK: - Session aggregate state

  private var totalDBSum: Double = 0
  private var totalDBCount = 0
  private var sessionSnoringDuration: TimeInterval = 0
  private var lastUpdateTime: Date?

  // MARK: - Per-event compression tasks

  private var pendingEventTasks: [Task<Void, Never>] = []

  /// `snoreDetector` is injectable so tests can check the sensitivity presets
  /// on their own instance; the app uses `.shared`.
  init(
    snoreDetector: SnoreDetector = .shared,
    audioRecorder: any AudioRecording = Container.shared.audioRecorder(),
    snoreInterrupterPlayer: any SnoreInterrupterPlaying = Container.shared.snoreInterrupterPlayer(),
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    pendingSessionStore: any PendingSessionStoring = Container.shared.pendingSessionStore(),
    checkpointStore: any SessionCheckpointStoring = Container.shared.sessionCheckpointStore(),
    rawLogWriter: any SessionRawLogWriting = Container.shared.sessionRawLogWriter(),
    clock: @escaping @MainActor () -> Date = Date.init)
  {
    self.clock = clock
    machine = DetectionStateMachine(settings: Self.settings(preferences: preferences, snoreDetector: snoreDetector))
    self.snoreDetector = snoreDetector
    self.audioRecorder = audioRecorder
    self.snoreInterrupterPlayer = snoreInterrupterPlayer
    self.preferences = preferences
    self.pendingSessionStore = pendingSessionStore
    self.checkpointStore = checkpointStore
    self.rawLogWriter = rawLogWriter
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMelodyDidStop),
      name: .snoreInterrupterDidStop,
      object: nil)
  }

  // MARK: - Lifecycle hooks (called by SessionRecordingController)

  func setActive(_ active: Bool) {
    isActive = active
  }

  func resetDisplayState() {
    currentDB = -160.0
    currentDetectionState = .none
    currentSpeechDetected = false
    eventsCount = 0
  }

  func syncEventsCount(with session: SleepSession) {
    eventsCount = session.eventsCount
  }

  /// Finalizes any in-progress snore/speech events. Call BEFORE stopping the
  /// audio engine: finalization captures the raw .caf URL; if stopRecording()
  /// runs first, currentEventFile is nilled and the event's audio is lost.
  func finalizeActiveEventsIfNeeded() {
    syncSettings()
    let now = clock()
    perform(machine.finalizeActiveEvents(at: now), at: now)
  }

  /// Waits for any in-flight per-event compression tasks to finish.
  func awaitPendingCompression() async {
    for task in pendingEventTasks {
      await task.value
    }
    pendingEventTasks.removeAll()
  }

  /// Writes a recovery snapshot of the in-progress session to disk so it can
  /// be reconstructed after a crash. Called after each event finalizes (and
  /// after its clip compresses) plus periodically from the processing loop.
  func checkpoint() {
    guard let session = recording?.currentSession else { return }
    let snapshot = SessionRecoverySnapshot(from: session, checkpointDate: Date())
    checkpointStore.write(snapshot)
  }

  /// Calibrated thresholds + SoundAnalysis confidence gates for the full-band
  /// capture path. Low = noisier rooms / stricter filtering;
  /// Medium = typical quiet bedroom (default); High = very quiet rooms.
  ///
  /// loud/epic lowered by 5 dB (2026-06-01) because RMS over 23 ms buffers
  /// under-reports impulsive snoring peaks. Peak-dB classification now
  /// compensates, but the thresholds were still sitting above real captured
  /// levels for loud snoring at typical bedside distances.
  func applyDetectionSensitivity() {
    apply(preferences.detectionSensitivity)
  }

  func apply(_ sensitivity: UserPreferences.DetectionSensitivity) {
    switch sensitivity {
    case .low:
      snoreDetector.quietThreshold = -45.0
      snoreDetector.lightThreshold = -35.0
      snoreDetector.loudThreshold = -15.0
      snoreDetector.epicThreshold = -5.0
      snoreDetector.confidenceGate = 0.45
      snoreDetector.highConfidenceGate = 0.65
      snoreDetector.quietFallbackGate = 0.55
    case .medium:
      snoreDetector.quietThreshold = -50.0
      snoreDetector.lightThreshold = -40.0
      snoreDetector.loudThreshold = -20.0
      snoreDetector.epicThreshold = -10.0
      snoreDetector.confidenceGate = 0.35
      snoreDetector.highConfidenceGate = 0.55
      snoreDetector.quietFallbackGate = 0.45
    case .high:
      snoreDetector.quietThreshold = -55.0
      snoreDetector.lightThreshold = -45.0
      snoreDetector.loudThreshold = -25.0
      snoreDetector.epicThreshold = -15.0
      snoreDetector.confidenceGate = 0.25
      snoreDetector.highConfidenceGate = 0.45
      snoreDetector.quietFallbackGate = 0.35
    }
  }

  // MARK: - Real-time audio processing

  /// Call this from the view when `audioRecorder.currentDB` changes.
  func processAudioLevel(db: Float) {
    processAudioLevel(db: db, peakDB: nil, spectralScore: 0, snoreConfidence: 0, speechConfidence: 0)
  }

  /// Call this from the view when audio features are available.
  func processAudioLevel(db: Float, peakDB: Float? = nil, spectralScore: Float = 0, snoreConfidence: Float = 0, speechConfidence: Float = 0) {
    guard isActive, let session = recording?.currentSession else { return }

    let now = clock()
    let rawDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
    let timeDelta = min(rawDelta, 0.5) // Cap to avoid spikes after background/resume
    lastUpdateTime = now

    // Don't process stale audio data while the mic is paused for melody playback.
    // The tap is removed during pause, so currentDB/spectralScore/snoreConfidence
    // are stale. Processing them creates false events and prematurely stops the melody.
    guard !audioRecorder.isPaused else { return }

    currentDB = db

    // Update running aggregates
    totalDBSum += Double(db)
    totalDBCount += 1
    if Double(db) > session.peakDB {
      session.peakDB = Double(db)
    }

    // Classify snoring state (SoundAnalysis → FFT → thresholds).
    // Use peakDB for intensity — snoring is impulsive and peak carries
    // more perceptual loudness than RMS over a 23 ms buffer.
    let classifyDB = peakDB ?? db
    // Spectral fallback stays off: FFTAnalyzer returned zeros until F21-T9, so live
    // detection has only ever used SoundAnalysis. Pass `spectralScore` here once a
    // real night validates the fallback. Logs and events still record the real score.
    let state = snoreDetector.classify(db: classifyDB, spectralScore: 0, snoreConfidence: snoreConfidence)
    #if DEBUG
    if snoreConfidence > 0.1 || spectralScore > 0.1 || speechConfidence > 0.1 {
      print("[SessionManager] classify rms=\(String(format: "%.1f", db)) peak=\(String(format: "%.1f", classifyDB)) spectral=\(String(format: "%.2f", spectralScore)) snoreConf=\(String(format: "%.2f", snoreConfidence)) speechConf=\(String(format: "%.2f", speechConfidence)) → snore=\(state) speech=\(speechDetector.isSpeechDetected)")
    }
    #endif

    // Update display state immediately for UI responsiveness
    currentDetectionState = state

    // Update parallel speech detection
    speechDetector.update(db: db, speechConfidence: speechConfidence)
    currentSpeechDetected = speechDetector.isSpeechDetected

    // Append to raw classification log for future re-processing (debug only).
    if preferences.preserveRawAudio {
      Task { [rawLogWriter] in
        await rawLogWriter.append(
          at: now,
          db: db,
          peakDB: peakDB,
          spectralScore: spectralScore,
          snoreConfidence: snoreConfidence,
          speechConfidence: speechConfidence,
          state: state)
      }
    }

    // Accumulate snoring duration
    if state != .none {
      sessionSnoringDuration += timeDelta
    }

    syncSettings()
    let input = DetectionInput(
      db: db,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      snoreState: state,
      isSpeech: currentSpeechDetected,
      isMelodyPlaying: snoreInterrupterPlayer.isPlaying)
    perform(machine.ingest(input, at: now), at: now)

    // Update stored aggregate (averageDB only; others are computed on demand)
    if totalDBCount > 0 {
      session.averageDB = totalDBSum / Double(totalDBCount)
    }
  }

  // MARK: - Reset

  func reset() {
    machine = DetectionStateMachine(settings: Self.settings(preferences: preferences, snoreDetector: snoreDetector))
    totalDBSum = 0
    totalDBCount = 0
    sessionSnoringDuration = 0
    lastUpdateTime = nil
    currentSpeechDetected = false
    pendingEventTasks.removeAll(keepingCapacity: false)
  }

  // MARK: - Melody gap handling

  /// Every melody stop, whether from `.melodyStopRequested`, its own timer, or
  /// the user, arrives here through `.snoreInterrupterDidStop`.
  @objc private func handleMelodyDidStop() {
    let now = clock()
    perform(machine.melodyDidStop(at: now), at: now)
  }

  /// Logs a recording gap directly on the session. Called whenever the Snore Interrupter
  /// stops (mic resumes), ensuring gaps are counted even if notification delivery fails.
  private func logRecordingGap(start: Date, duration: TimeInterval, snoringResumed: Bool = true) {
    guard let session = recording?.currentSession, duration > 0 else { return }
    let startOffset = start.timeIntervalSince(session.startDate)
    guard startOffset >= 0 else { return }
    var gaps = session.recordingGaps ?? []
    gaps.append(RecordingGap(startOffset: startOffset, duration: duration, snoringResumed: snoringResumed))
    session.recordingGaps = gaps
    print("[SessionManager] Logged gap: startOffset=\(String(format: "%.1f", startOffset))s duration=\(String(format: "%.1f", duration))s snoringResumed=\(snoringResumed)")
  }

  /// Marks the most recent recording gap as having confirmed snoring resumption.
  /// Called when sustained snoring is detected within the post-melody breathing delay.
  private func markLastGapSnoringResumed() {
    guard let session = recording?.currentSession, var gaps = session.recordingGaps, !gaps.isEmpty else { return }
    gaps[gaps.count - 1].snoringResumed = true
    session.recordingGaps = gaps
  }

  // MARK: - Performing machine outputs

  private func perform(_ outputs: [DetectionOutput], at now: Date) {
    for output in outputs {
      switch output {
      case let .snoreEventStarted(id, _):
        startEventClip(id: id)
      case .melodyRequested:
        let wasPlaying = snoreInterrupterPlayer.isPlaying
        snoreInterrupterPlayer.playIfNeeded()
        if snoreInterrupterPlayer.isPlaying, !wasPlaying {
          lastUpdateTime = nil
          perform(machine.melodyDidStart(at: now), at: now)
        }
      case .melodyStopRequested:
        print("[SessionManager] Sustained non-snore — stopping melody")
        snoreInterrupterPlayer.stop()
      case .eventClipClosed:
        _ = audioRecorder.finalizeEventFile()
      case .snoringResumedAfterMelody:
        markLastGapSnoringResumed()
      case let .recordingGap(start, duration):
        logRecordingGap(start: start, duration: duration, snoringResumed: false)
      case let .snoreEventFinalized(event):
        save(event)
      case let .snoreEventDiscarded(id, reason):
        print("[SessionManager] Snore event discarded: \(reason)")
        if let session = recording?.currentSession {
          try? FileManager.default.removeItem(at: eventFileURL(eventID: id, sessionID: session.id))
        }
        audioRecorder.finalizeEventFile()
      case let .speechEventFinalized(event):
        save(event)
      }
    }
  }

  private func startEventClip(id: UUID) {
    guard let session = recording?.currentSession else { return }
    let fileURL = eventFileURL(eventID: id, sessionID: session.id)
    do {
      try audioRecorder.startEventFile(eventID: id, url: fileURL)
      pendingSessionStore.addFile(fileURL.lastPathComponent)
    } catch {
      print("[SessionManager] Failed to start event file: \(error)")
    }
  }

  private func save(_ detected: DetectedSnoreEvent) {
    guard let session = recording?.currentSession else { return }
    let event = SnoreEvent(
      id: detected.id,
      timestamp: detected.start,
      category: .snoring,
      intensity: detected.intensity,
      averageDB: detected.averageDB,
      peakDB: detected.peakDB,
      averageConfidence: detected.averageConfidence,
      averageSpectralScore: detected.averageSpectralScore,
      bursts: detected.bursts.isEmpty ? nil : detected.bursts,
      duration: detected.duration)
    append(event, to: session)

    // Close the event audio file and compress to .m4a
    if let rawFileURL = audioRecorder.finalizeEventFile() {
      let task = Task { @MainActor in
        let m4aURL = rawFileURL.deletingPathExtension().appendingPathExtension("m4a")
        if await EventClipCompressor.compress(from: rawFileURL, to: m4aURL) {
          let spectral = await AudioClipExtractor.analyzeSpectralFeatures(of: m4aURL)
          event.audioFileURL = AudioFileURLResolver.filename(from: m4aURL)
          event.dominantFrequency = spectral.dominantFrequency
          event.spectralCentroid = spectral.spectralCentroid
          event.lowFreqRatio = spectral.lowFreqRatio
          self.pendingSessionStore.addFile(m4aURL.lastPathComponent)
          // Delete raw .caf
          try? FileManager.default.removeItem(at: rawFileURL)
          // Re-checkpoint now that the event's clip URL is set.
          self.checkpoint()
        }
      }
      pendingEventTasks.append(task)
    }

    // Capture this event's metadata immediately; the clip URL is added by a
    // second checkpoint once compression finishes.
    checkpoint()
  }

  private func save(_ detected: DetectedSpeechEvent) {
    guard let session = recording?.currentSession else { return }
    let event = SnoreEvent(
      timestamp: detected.start,
      category: .sleepTalking,
      intensity: .quiet,
      averageDB: detected.averageDB,
      peakDB: detected.peakDB,
      duration: detected.duration)
    append(event, to: session)
    checkpoint()
  }

  private func append(_ event: SnoreEvent, to session: SleepSession) {
    event.session = session
    if session.events == nil {
      session.events = []
    }
    session.events?.append(event)
    eventsCount = session.events?.count ?? 0
  }

  // MARK: - Private helpers

  /// Re-read every tick, as before the extraction: sleep talking and the
  /// minimum duration follow the live preferences; the confidence gate follows
  /// the detector, which `applyDetectionSensitivity()` sets at session start.
  private func syncSettings() {
    machine.settings = Self.settings(preferences: preferences, snoreDetector: snoreDetector)
  }

  private static func settings(
    preferences: any UserPreferencesStoring,
    snoreDetector: SnoreDetector) -> DetectionStateMachine.Settings
  {
    DetectionStateMachine.Settings(
      minEventDuration: minEventDuration(for: preferences.detectionSensitivity),
      highConfidenceGate: snoreDetector.highConfidenceGate,
      detectSleepTalking: preferences.detectSleepTalking)
  }

  /// Minimum snore-event duration. Sensitivity-dependent so isolated single
  /// snores (~1 s) are retained on Medium/High while Low still filters
  /// transient sounds. Ground-truthed against bedroom recordings.
  private static func minEventDuration(for sensitivity: UserPreferences.DetectionSensitivity) -> TimeInterval {
    switch sensitivity {
    case .low: 2.0
    case .medium: 1.0
    case .high: 0.5
    }
  }

  private func eventFileURL(eventID: UUID, sessionID: UUID) -> URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("event_\(eventID.uuidString)_session_\(sessionID.uuidString).caf")
  }
}
