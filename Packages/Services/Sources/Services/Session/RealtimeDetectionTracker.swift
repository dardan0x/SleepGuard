import AudioEngine
import Config
import FactoryKit
import Foundation
import Models
import os
import SleepAudioKit
import SleepCore
import SleepLogging
import SleepStore
import UIKit

/// Adapter between the 50 ms processing loop and `DetectionEngine`.
///
/// Each tick it classifies the sample (SleepCore's `LiveSampleClassifier`) and
/// sends it, timestamped, into the engine's stream; melody stops and settings
/// changes go into the same stream, so the engine sees them in the order they
/// happened. The engine runs `DetectionStateMachine` on its own actor and
/// hands the outputs back here, where they are performed on the main actor:
/// event clips, SwiftData events and gaps, the Snore Interrupter, clip
/// compression and recovery checkpoints. See ADR 0003.
///
/// Session ownership stays with the controller; the tracker reaches it (and
/// the recording flag) through `recording`.
@MainActor
@Observable
final class RealtimeDetectionTracker {
  /// Real-time state for UI observation, published at most every
  /// `displayInterval` (5 Hz) rather than on every 50 ms sample.
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
  /// The snore and speech verdicts, SleepCore's (the same as SleepGuardUIKitWay's).
  private(set) var classifier = LiveSampleClassifier(sensitivity: .medium)
  private let snoreInterrupterPlayer: any SnoreInterrupterPlaying
  private let preferences: any UserPreferencesStoring
  private let pendingSessionStore: any PendingSessionStoring
  private let checkpointStore: any SessionCheckpointStoring
  private let rawLogWriter: any SessionRawLogWriting
  /// Sample timestamps. Tests pass a scripted clock to drive time-based rules.
  private let clock: @MainActor () -> Date

  /// Set by the controller while a session is recording.
  private var isActive = false

  // MARK: - Detection engine

  /// The open engine's input. `nil` once `finishDetection()` has closed it.
  private var continuation: AsyncStream<DetectionEngine.Message>.Continuation?
  private var engineTask: Task<Void, Never>?
  /// Bumped per engine, so a batch from a replaced engine is never performed
  /// against the next session.
  private var generation = 0
  private var lastSentSettings: DetectionStateMachine.Settings?

  static let displayInterval: TimeInterval = 0.2
  private var lastDisplayUpdate: Date?

  // MARK: - Session aggregate state

  private var totalDBSum: Double = 0
  private var totalDBCount = 0
  private var sessionSnoringDuration: TimeInterval = 0
  private var lastUpdateTime: Date?

  // MARK: - Per-event compression tasks

  private var pendingEventTasks: [Task<Void, Never>] = []
  /// The open event's clip, closed early for the melody (the microphone
  /// pauses): kept until the event is saved or discarded.
  private var closedClipURL: URL?
  /// Instruments intervals for open snore events (Points of Interest).
  private var eventSignposts: [UUID: OSSignpostIntervalState] = [:]

  /// Collaborators default to the container; tests pass their own detectors
  /// so parallel runs don't share classification state.
  init(
    audioRecorder: any AudioRecording = Container.shared.audioRecorder(),
    snoreInterrupterPlayer: any SnoreInterrupterPlaying = Container.shared.snoreInterrupterPlayer(),
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    pendingSessionStore: any PendingSessionStoring = Container.shared.pendingSessionStore(),
    checkpointStore: any SessionCheckpointStoring = Container.shared.sessionCheckpointStore(),
    rawLogWriter: any SessionRawLogWriting = Container.shared.sessionRawLogWriter(),
    clock: @escaping @MainActor () -> Date = Date.init)
  {
    self.clock = clock
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
      // Only this tracker's player: a stop from any other instance (another
      // test's, say) must not end this session's melody gap.
      object: snoreInterrupterPlayer)
    startEngine()
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
    lastDisplayUpdate = nil
  }

  func syncEventsCount(with session: NightRecord) {
    eventsCount = session.night.eventCount
  }

  /// Finalizes any in-progress snore/speech events and waits until the engine
  /// has performed every output, then closes it (`reset()` opens the next).
  /// Call BEFORE stopping the audio engine: finalization captures the raw .caf
  /// URL; if stopRecording() runs first, currentEventFile is nilled and the
  /// event's audio is lost.
  func finishDetection() async {
    guard let continuation else { return }
    sendSettingsIfChanged()
    continuation.yield(.finalize(at: clock()))
    continuation.finish()
    self.continuation = nil
    await engineTask?.value
    engineTask = nil
  }

  /// Waits until the engine has handled everything sent so far and performed
  /// its outputs.
  func waitUntilProcessed() async {
    guard let continuation else { return }
    await withCheckedContinuation { done in
      continuation.yield(.barrier(done))
    }
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
    var night = session.night
    night.end = max(Date(), night.start)
    checkpointStore.write(night)
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

  /// SleepCore's calibrated preset for `sensitivity`.
  func apply(_ sensitivity: UserPreferences.DetectionSensitivity) {
    classifier.update(sensitivity: sensitivity)
  }

  // MARK: - Real-time audio processing

  /// Call this from the view when `audioRecorder.currentDB` changes.
  func processAudioLevel(db: Float) {
    processAudioLevel(db: db, peakDB: nil, spectralScore: 0, snoreConfidence: 0, speechConfidence: 0)
  }

  /// Call this from the view when audio features are available. `time` is the
  /// sample's time (the decimator's window end); `nil` reads the clock.
  func processAudioLevel(
    db: Float,
    peakDB: Float? = nil,
    spectralScore: Float = 0,
    snoreConfidence: Float = 0,
    speechConfidence: Float = 0,
    at time: Date? = nil)
  {
    guard isActive, let session = recording?.currentSession else { return }

    let now = time ?? clock()
    let rawDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
    let timeDelta = min(rawDelta, 0.5) // Cap to avoid spikes after background/resume
    lastUpdateTime = now

    // Don't process stale audio data while the mic is paused for melody playback.
    // The tap is removed during pause, so currentDB/spectralScore/snoreConfidence
    // are stale. Processing them creates false events and prematurely stops the melody.
    guard !audioRecorder.isPaused else { return }

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
    // SleepCore's LiveSampleClassifier: snore on the peak (spectral fallback
    // off until a real night validates it), speech on the RMS level.
    let verdict = classifier.input(
      for: .init(
        db: db, peakDB: peakDB, spectralScore: spectralScore, snoreConfidence: snoreConfidence,
        speechConfidence: speechConfidence),
      isMelodyPlaying: false)
    let state = verdict.snoreState
    let isSpeech = verdict.isSpeech
    #if DEBUG
    if snoreConfidence > 0.1 || spectralScore > 0.1 || speechConfidence > 0.1 {
      Log.detection.debug("classify rms=\(db, format: .fixed(precision: 1)) peak=\(classifyDB, format: .fixed(precision: 1)) spectral=\(spectralScore, format: .fixed(precision: 2)) snoreConf=\(snoreConfidence, format: .fixed(precision: 2)) speechConf=\(speechConfidence, format: .fixed(precision: 2)) → snore=\(String(describing: state), privacy: .public) speech=\(isSpeech)")
    }
    #endif

    if lastDisplayUpdate.map({ now.timeIntervalSince($0) >= Self.displayInterval }) ?? true {
      lastDisplayUpdate = now
      currentDB = db
      currentDetectionState = state
      currentSpeechDetected = isSpeech
    }

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

    sendSettingsIfChanged()
    let input = DetectionInput(
      db: db,
      spectralScore: spectralScore,
      snoreConfidence: snoreConfidence,
      snoreState: state,
      isSpeech: isSpeech,
      isMelodyPlaying: snoreInterrupterPlayer.isPlaying)
    continuation?.yield(.sample(input, at: now))

    // Update stored aggregate (averageDB only; others are computed on demand)
    if totalDBCount > 0 {
      session.averageDB = totalDBSum / Double(totalDBCount)
    }
  }

  // MARK: - Reset

  func reset() {
    startEngine()
    totalDBSum = 0
    totalDBCount = 0
    sessionSnoringDuration = 0
    lastUpdateTime = nil
    currentSpeechDetected = false
    pendingEventTasks.removeAll(keepingCapacity: false)
    eventSignposts.removeAll()
    closedClipURL = nil
  }

  // MARK: - Melody gap handling

  /// Every melody stop, whether from `.melodyStopRequested`, its own timer, or
  /// the user, arrives here through `.snoreInterrupterDidStop`.
  @objc private func handleMelodyDidStop() {
    continuation?.yield(.melodyDidStop(at: clock()))
  }

  /// Capture was interrupted (a call, another app) or runs again. Goes through
  /// the stream like every other detection input (ADR 0003): the engine ends
  /// open events and turns the paused span into an interruption gap.
  func captureDidChange(interrupted: Bool, at time: Date) {
    continuation?.yield(interrupted ? .captureDidPause(at: time) : .captureDidResume(at: time))
  }

  /// Logs a recording gap directly on the session. Called whenever the Snore Interrupter
  /// stops (mic resumes), ensuring gaps are counted even if notification delivery fails.
  private func logRecordingGap(
    start: Date,
    duration: TimeInterval,
    snoringResumed: Bool = true,
    kind: RecordingGap.Kind = .melody)
  {
    guard let session = recording?.currentSession else { return }
    let gaps = session.recordingGaps
    let updated = gaps.adding(
      start: start, duration: duration, nightStart: session.start, snoringResumed: snoringResumed, kind: kind)
    guard updated.count > gaps.count else { return }
    session.recordingGaps = updated
    let startOffset = start.timeIntervalSince(session.start)
    Log.detection.info("Logged gap: startOffset=\(startOffset, format: .fixed(precision: 1))s duration=\(duration, format: .fixed(precision: 1))s snoringResumed=\(snoringResumed) kind=\(kind.rawValue, privacy: .public)")
  }

  /// Marks the most recent recording gap as having confirmed snoring resumption.
  /// Called when sustained snoring is detected within the post-melody breathing delay.
  private func markLastGapSnoringResumed() {
    guard let session = recording?.currentSession, !session.recordingGaps.isEmpty else { return }
    session.recordingGaps = session.recordingGaps.markingLastSnoringResumed()
  }

  // MARK: - Engine lifecycle

  /// Replaces the engine with a fresh one (new session state). Any previous
  /// engine's stream is closed and its remaining batches are ignored.
  private func startEngine() {
    continuation?.finish()
    generation += 1
    let generation = generation
    let settings = Self.settings(preferences: preferences, classifier: classifier)
    lastSentSettings = settings
    let engine = DetectionEngine(settings: settings)
    let (stream, continuation) = DetectionEngine.makeStream()
    self.continuation = continuation
    let perform: DetectionEngine.Perform = { [weak self] batch in
      await self?.perform(batch, generation: generation) ?? []
    }
    engineTask = Task {
      await engine.run(stream, perform: perform)
    }
  }

  // MARK: - Performing engine outputs

  /// Performs one batch and returns the feedback for the engine: the melody
  /// actually started.
  private func perform(_ batch: DetectionEngine.Batch, generation: Int) -> [DetectionEngine.Message] {
    guard generation == self.generation else { return [] }
    var feedback: [DetectionEngine.Message] = []
    for output in batch.outputs {
      switch output {
      case let .snoreEventStarted(id, _):
        eventSignposts[id] = Log.signposter.beginInterval("Snore event", id: Log.signposter.makeSignpostID())
        startEventClip(id: id)
      case .melodyRequested:
        let wasPlaying = snoreInterrupterPlayer.isPlaying
        snoreInterrupterPlayer.playIfNeeded()
        if snoreInterrupterPlayer.isPlaying, !wasPlaying {
          lastUpdateTime = nil
          feedback.append(.melodyDidStart(at: batch.time))
        }
      case .melodyStopRequested:
        Log.detection.debug("Sustained non-snore — stopping melody")
        snoreInterrupterPlayer.stop()
      case .eventClipClosed:
        // Kept for the event's save: the melody pauses the microphone, the
        // event goes on.
        if let url = audioRecorder.finalizeEventFile() { closedClipURL = url }
      case .snoringResumedAfterMelody:
        markLastGapSnoringResumed()
      case let .recordingGap(start, duration):
        logRecordingGap(start: start, duration: duration, snoringResumed: false)
      case let .interruptionGap(start, duration):
        logRecordingGap(start: start, duration: duration, snoringResumed: false, kind: .interruption)
      case let .snoreEventFinalized(event):
        endEventSignpost(id: event.id, outcome: "saved")
        save(event)
      case let .snoreEventDiscarded(id, reason):
        Log.detection.debug("Snore event discarded: \(String(describing: reason), privacy: .public)")
        endEventSignpost(id: id, outcome: "discarded")
        audioRecorder.discardEventFile()
        if let closedClipURL {
          try? FileManager.default.removeItem(at: closedClipURL)
          self.closedClipURL = nil
        }
      case let .speechEventFinalized(event):
        save(event)
      }
    }
    return feedback
  }

  private func startEventClip(id: UUID) {
    guard recording?.currentSession != nil else { return }
    closedClipURL = nil
    do {
      try audioRecorder.startEventFile(eventID: id)
      // SleepGuardShared's engine names it `<id>.caf` in the clips folder.
      pendingSessionStore.addFile("\(id.uuidString).caf")
    } catch {
      Log.detection.error("Failed to start event file: \(String(describing: error), privacy: .public)")
    }
  }

  private func save(_ detected: DetectedSnoreEvent) {
    guard let session = recording?.currentSession else { return }
    let event = NightEventRecord.make(from: NightEvent(
      id: detected.id, start: detected.start, duration: detected.duration, category: .snoring,
      intensity: detected.intensity, averageDB: detected.averageDB, peakDB: detected.peakDB,
      averageConfidence: detected.averageConfidence, bursts: detected.bursts,
      averageSpectralScore: detected.averageSpectralScore))
    append(event, to: session)

    // Close the event audio file (or take the one the melody closed) and
    // compress it to .m4a (SleepGuardShared's ClipCompressor).
    let clipURL = audioRecorder.finalizeEventFile() ?? closedClipURL
    closedClipURL = nil
    if let rawFileURL = clipURL {
      let task = Task { @MainActor in
        let m4aURL = rawFileURL.deletingPathExtension().appendingPathExtension("m4a")
        if await ClipCompressor.compress(from: rawFileURL, to: m4aURL) {
          let spectral = await ClipSpectrum.features(of: m4aURL)
          event.clipFileName = AudioFileURLResolver.filename(from: m4aURL)
          event.dominantFrequency = spectral.dominantFrequency
          event.spectralCentroid = spectral.spectralCentroid
          event.lowFreqRatio = spectral.lowFreqRatio
          self.pendingSessionStore.addFile(m4aURL.lastPathComponent)
          // Delete raw .caf
          try? FileManager.default.removeItem(at: rawFileURL)
          // Re-checkpoint now that the event's clip URL is set.
          self.checkpoint()
        } else {
          Log.audio.error("Clip compression failed; event saved without a clip")
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
    let event = NightEventRecord.make(from: NightEvent(
      start: detected.start, duration: detected.duration, category: .sleepTalking, intensity: .quiet,
      averageDB: detected.averageDB, peakDB: detected.peakDB))
    append(event, to: session)
    checkpoint()
  }

  private func append(_ event: NightEventRecord, to session: NightRecord) {
    event.session = session
    session.events.append(event)
    eventsCount = session.events.count
  }

  // MARK: - Private helpers

  private func endEventSignpost(id: UUID, outcome: StaticString) {
    guard let state = eventSignposts.removeValue(forKey: id) else { return }
    Log.signposter.endInterval("Snore event", state, "\(outcome)")
  }

  /// Re-read every tick, as before the extraction: sleep talking and the
  /// minimum duration follow the live preferences; the confidence gate follows
  /// the detector, which `applyDetectionSensitivity()` sets at session start.
  /// Sent only when something changed, ahead of the sample it applies to.
  private func sendSettingsIfChanged() {
    let settings = Self.settings(preferences: preferences, classifier: classifier)
    guard settings != lastSentSettings else { return }
    lastSentSettings = settings
    continuation?.yield(.settings(settings))
  }

  private static func settings(
    preferences: any UserPreferencesStoring,
    classifier: LiveSampleClassifier) -> DetectionStateMachine.Settings
  {
    DetectionStateMachine.Settings(
      minEventDuration: preferences.detectionSensitivity.minEventDuration,
      highConfidenceGate: classifier.snore.highConfidenceGate,
      detectSleepTalking: preferences.detectSleepTalking)
  }
}
