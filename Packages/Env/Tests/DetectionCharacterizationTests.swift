import EnvTestSupport
import Foundation
import Models
import Observation
import Testing
@testable import AudioEngine
@testable import Env

/// End-to-end behavior of `RealtimeDetectionTracker` on scripted 50 ms samples:
/// the events, bursts, gaps and melody calls a session ends up with. Written
/// against the tracker before `DetectionStateMachine` was extracted (F22-T8), so
/// the extraction has to reproduce every line.
///
/// Each test is synchronous on the main actor, so the controller's own 50 ms
/// loop never runs between scripted samples.
@MainActor
struct DetectionCharacterizationTests {
  // MARK: - Snore events

  @Test func sustainedSnoringBecomesOneEvent() throws {
    let harness = try DetectionHarness()
    harness.silence(1)
    harness.snore(3, db: -35, confidence: 0.6)
    harness.silence(11)
    #expect(harness.summary() == [
      "snoring light t=1.05 d=2.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-3.00]",
      "melody requests=58 stops=0",
    ])
  }

  @Test func twoSnoringSamplesAreIgnored() throws {
    let harness = try DetectionHarness()
    harness.snore(0.1, db: -35, confidence: 0.6)
    harness.silence(11)
    #expect(harness.summary() == ["melody requests=0 stops=0"])
  }

  @Test(arguments: [
    (UserPreferences.DetectionSensitivity.medium, false),
    (.high, true),
  ])
  func minimumDurationDependsOnSensitivity(sensitivity: UserPreferences.DetectionSensitivity, kept: Bool) throws {
    let harness = try DetectionHarness(sensitivity: sensitivity)
    harness.snore(0.8, db: -35, confidence: 0.6)
    harness.silence(11)
    #expect(harness.events.count == (kept ? 1 : 0))
  }

  @Test(arguments: [(Float(0.4), false), (0.6, true)])
  func shortEventsNeedHighConfidence(confidence: Float, kept: Bool) throws {
    let harness = try DetectionHarness()
    harness.snore(2, db: -35, confidence: confidence)
    harness.silence(11)
    #expect(harness.events.count == (kept ? 1 : 0))
  }

  @Test func briefPauseSplitsBurstsButNotTheEvent() throws {
    let harness = try DetectionHarness()
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(2)
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(11)
    #expect(harness.summary() == [
      "snoring light t=0.05 d=5.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-2.00, 4.10-6.00]",
      "melody requests=76 stops=0",
    ])
  }

  @Test func intensityKeepsTheLoudestTier() throws {
    let harness = try DetectionHarness()
    harness.snore(1.5, db: -35, confidence: 0.6)
    harness.snore(1.5, db: -15, confidence: 0.6)
    harness.silence(11)
    #expect(harness.summary() == [
      "snoring loud t=0.05 d=2.95 avg=-24.7 peak=-15.0 conf=0.60 bursts=[0.00-3.00]",
      "melody requests=58 stops=0",
    ])
  }

  @Test func sessionEndFinalizesTheOpenEvent() throws {
    let harness = try DetectionHarness()
    harness.snore(4, db: -35, confidence: 0.6)
    harness.tracker.finalizeActiveEventsIfNeeded()
    #expect(harness.summary() == [
      "snoring light t=0.05 d=3.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-3.95]",
      "melody requests=78 stops=0",
    ])
  }

  // MARK: - Snore Interrupter

  /// The melody pauses the mic; snoring resumes within the 3 s breathing delay,
  /// so the first gap counts as snoring and the event spans it. Resumed snoring
  /// re-triggers the melody; after the second gap nothing resumes, so the event
  /// ends at the last snoring sample before it.
  @Test func melodyGapWithResumedSnoringExtendsTheEvent() throws {
    let harness = try DetectionHarness(melody: .pausesMic)
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(5)
    harness.interrupter.stop()
    harness.silence(1)
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(3)
    harness.interrupter.stop()
    harness.silence(11)
    #expect(harness.summary() == [
      "snoring light t=0.05 d=8.10 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-0.10, 8.10-8.10]",
      "gap t=0.15 d=6.85 resumed=true",
      "gap t=8.15 d=4.85 resumed=false",
      "melody requests=2 stops=2",
    ])
  }

  /// No snoring within the breathing delay: the event is cut back to where
  /// snoring was before the melody, and the gap doesn't count. The melody starts
  /// on the onset sample, so that span is 0.10 s, under every minimum duration:
  /// the event is discarded and only the gap remains. (Pinned, not endorsed.)
  @Test func melodyGapWithoutSnoringDiscardsTheEvent() throws {
    let harness = try DetectionHarness(melody: .pausesMic)
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(5)
    harness.interrupter.stop()
    harness.silence(11)
    #expect(harness.summary() == [
      "gap t=0.15 d=6.85 resumed=false",
      "melody requests=1 stops=1",
    ])
  }

  /// With the mic still live, sustained silence stops the melody, but only
  /// after its 4 s minimum play time.
  @Test func sustainedSilenceStopsTheMelodyAfterItsMinimumPlayTime() throws {
    let harness = try DetectionHarness(melody: .keepsMicLive)
    harness.snore(1, db: -35, confidence: 0.6)
    harness.silence(6)
    #expect(harness.summary() == [
      "gap t=0.15 d=4.00 resumed=false",
      "melody requests=16 stops=1",
    ])
  }

  // MARK: - Sleep talking

  @Test func speechBecomesASleepTalkingEvent() throws {
    let harness = try DetectionHarness(sleepTalking: true)
    harness.speech(2, db: -40, confidence: 0.8)
    harness.silence(11)
    #expect(harness.summary() == [
      "sleepTalking quiet t=0.05 d=1.95 avg=-40.0 peak=-40.0 conf=0.00 bursts=[]",
      "melody requests=0 stops=0",
    ])
  }

  @Test func snoringEndsTheSpeechEventImmediately() throws {
    let harness = try DetectionHarness(sleepTalking: true)
    harness.speech(2, db: -40, confidence: 0.8)
    harness.snore(2, db: -35, confidence: 0.6)
    harness.silence(11)
    #expect(harness.summary() == [
      "sleepTalking quiet t=0.05 d=2.00 avg=-40.0 peak=-40.0 conf=0.00 bursts=[]",
      "snoring light t=2.05 d=1.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-2.00]",
      "melody requests=38 stops=0",
    ])
  }

  @Test func speechIsIgnoredWhenSleepTalkingIsOff() throws {
    let harness = try DetectionHarness(sleepTalking: false)
    harness.speech(2, db: -40, confidence: 0.8)
    harness.silence(11)
    #expect(harness.summary() == ["melody requests=0 stops=0"])
  }
}

// MARK: - Harness

/// Settable time for the tracker's clock.
@MainActor
final class ScriptedClock {
  var now: Date
  init(_ now: Date) {
    self.now = now
  }
}

/// Behaves like `SnoreInterrupterPlayer` where the tracker can tell: `stop()`
/// posts `.snoreInterrupterDidStop` synchronously, and starting can pause the
/// mic (the real `AudioRecorder` does on `.snoreInterrupterWillPlay`).
@MainActor
@Observable
final class ScriptedInterrupter: SnoreInterrupterPlaying {
  enum Melody { case never, pausesMic, keepsMicLive }

  var isPlaying = false
  var currentMelodyName: String?
  var isMutedForSession = false
  private(set) var requests = 0
  private(set) var stops = 0
  private let melody: Melody
  private let recorder: FakeAudioRecorder

  init(melody: Melody, recorder: FakeAudioRecorder) {
    self.melody = melody
    self.recorder = recorder
  }

  func playIfNeeded() {
    requests += 1
    guard melody != .never, !isPlaying else { return }
    isPlaying = true
    if melody == .pausesMic { recorder.isPaused = true }
  }

  func stop() {
    let wasPlaying = isPlaying
    isPlaying = false
    if wasPlaying {
      stops += 1
      recorder.isPaused = false
    }
    NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: nil)
  }

  func muteForSession() { isMutedForSession = true }
  func resetSessionMute() { isMutedForSession = false }
}

@MainActor
final class DetectionHarness {
  let recorder = FakeAudioRecorder()
  let interrupter: ScriptedInterrupter
  let tracker: RealtimeDetectionTracker
  private let controller: SessionRecordingController
  private let clock: ScriptedClock
  private let start: Date
  private var tick = 0

  init(
    sensitivity: UserPreferences.DetectionSensitivity = .medium,
    sleepTalking: Bool = false,
    melody: ScriptedInterrupter.Melody = .never) throws
  {
    let preferences = UserPreferences.isolated()
    preferences.detectionSensitivity = sensitivity
    preferences.detectSleepTalking = sleepTalking
    let interrupter = ScriptedInterrupter(melody: melody, recorder: recorder)
    let pending = FakePendingSessionStore()
    let checkpoints = FakeSessionCheckpointStore()
    let rawLog = FakeSessionRawLogWriter()
    let clock = ScriptedClock(Date())
    controller = SessionRecordingController(
      audioRecorder: recorder,
      snoreInterrupterPlayer: interrupter,
      soundAnalysis: FakeSoundAnalysisDetector(),
      preferences: preferences,
      pendingSessionStore: pending,
      checkpointStore: checkpoints,
      rawLogWriter: rawLog)
    tracker = RealtimeDetectionTracker(
      snoreDetector: SnoreDetector(),
      audioRecorder: recorder,
      snoreInterrupterPlayer: interrupter,
      preferences: preferences,
      pendingSessionStore: pending,
      checkpointStore: checkpoints,
      rawLogWriter: rawLog,
      clock: { clock.now })
    tracker.recording = controller
    controller.attach(detection: tracker)
    try controller.startSession()
    start = try #require(controller.currentSession).startDate
    clock.now = start
    self.clock = clock
    self.interrupter = interrupter
  }

  isolated deinit {
    controller.stopAndDiscardSession()
  }

  var events: [SnoreEvent] {
    (controller.currentSession?.events ?? []).sorted { $0.timestamp < $1.timestamp }
  }

  func snore(_ seconds: Double, db: Float, confidence: Float) {
    feed(seconds, db: db, snoreConfidence: confidence, speechConfidence: 0)
  }

  func speech(_ seconds: Double, db: Float, confidence: Float) {
    feed(seconds, db: db, snoreConfidence: 0, speechConfidence: confidence)
  }

  func silence(_ seconds: Double) {
    feed(seconds, db: -60, snoreConfidence: 0, speechConfidence: 0)
  }

  /// One sample per 50 ms, timestamped from an integer tick so times don't drift.
  private func feed(_ seconds: Double, db: Float, snoreConfidence: Float, speechConfidence: Float) {
    for _ in 0..<Int((seconds / 0.05).rounded()) {
      tick += 1
      clock.now = start.addingTimeInterval(Double(tick) * 0.05)
      tracker.processAudioLevel(
        db: db, peakDB: nil, spectralScore: 0, snoreConfidence: snoreConfidence, speechConfidence: speechConfidence)
    }
  }

  func summary() -> [String] {
    let session = controller.currentSession
    let eventLines = events.map { event in
      let bursts = (event.bursts ?? []).map { "\(f($0.startOffset))-\(f($0.endOffset))" }.joined(separator: ", ")
      return "\(event.category.rawValue) \(event.intensity.rawValue) t=\(f(event.timestamp.timeIntervalSince(start))) "
        + "d=\(f(event.duration)) avg=\(f(event.averageDB, 1)) peak=\(f(event.peakDB, 1)) "
        + "conf=\(f(event.averageConfidence)) bursts=[\(bursts)]"
    }
    let gapLines = (session?.recordingGaps ?? []).map {
      "gap t=\(f($0.startOffset)) d=\(f($0.duration)) resumed=\($0.snoringResumed)"
    }
    return eventLines + gapLines + ["melody requests=\(interrupter.requests) stops=\(interrupter.stops)"]
  }

  private func f(_ value: Double, _ digits: Int = 2) -> String {
    String(format: "%.\(digits)f", value)
  }
}
