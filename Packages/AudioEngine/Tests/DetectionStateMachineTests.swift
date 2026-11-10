import Foundation
import Models
import Testing
@testable import AudioEngine

/// The pure detection state machine: samples and times in, outputs out.
/// No clock, no fakes, no SwiftData.
struct DetectionStateMachineTests {
  private static let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
  private let t0 = Date(timeIntervalSince1970: 1_000_000)

  private func machine(
    minEventDuration: TimeInterval = 1.0,
    highConfidenceGate: Float = 0.55,
    sleepTalking: Bool = false) -> DetectionStateMachine
  {
    DetectionStateMachine(
      settings: .init(
        minEventDuration: minEventDuration,
        highConfidenceGate: highConfidenceGate,
        detectSleepTalking: sleepTalking),
      makeID: { Self.eventID })
  }

  private static let snoring = DetectionInput(db: -35, snoreConfidence: 0.6, snoreState: .light)
  private static let silence = DetectionInput(db: -60, snoreState: .none)
  private static let speech = DetectionInput(db: -40, snoreState: .none, isSpeech: true)

  /// Feeds `count` samples 50 ms apart starting after `tick`, returning every output.
  @discardableResult
  private func feed(
    _ machine: inout DetectionStateMachine,
    _ input: DetectionInput,
    count: Int,
    from tick: inout Int) -> [DetectionOutput]
  {
    var outputs: [DetectionOutput] = []
    for _ in 0..<count {
      tick += 1
      outputs += machine.ingest(input, at: time(tick))
    }
    return outputs
  }

  private func time(_ tick: Int) -> Date {
    t0.addingTimeInterval(Double(tick) * 0.05)
  }

  private func finalized(_ outputs: [DetectionOutput]) -> [DetectedSnoreEvent] {
    outputs.compactMap { if case let .snoreEventFinalized(event) = $0 { event } else { nil } }
  }

  // MARK: - Onset

  @Test func eventStartsOnTheThirdSustainedSampleBackdatedToTheFirst() {
    var machine = machine()
    var tick = 0
    #expect(feed(&machine, Self.snoring, count: 2, from: &tick).isEmpty)
    let outputs = feed(&machine, Self.snoring, count: 1, from: &tick)
    #expect(outputs == [.snoreEventStarted(id: Self.eventID, start: time(1)), .melodyRequested])
    #expect(machine.hasActiveSnoreEvent)
  }

  @Test func silenceBetweenSamplesResetsTheOnsetCount() {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 2, from: &tick)
    feed(&machine, Self.silence, count: 1, from: &tick)
    feed(&machine, Self.snoring, count: 2, from: &tick)
    #expect(!machine.hasActiveSnoreEvent)
  }

  // MARK: - Finalization

  @Test func tenSecondsOfSilenceFinalizesTheEvent() throws {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 60, from: &tick)
    let beforeGap = feed(&machine, Self.silence, count: 199, from: &tick)
    #expect(finalized(beforeGap).isEmpty)
    let event = try #require(finalized(feed(&machine, Self.silence, count: 1, from: &tick)).first)
    #expect(event.start == time(1))
    #expect(abs(event.duration - 2.95) < 1e-6)
    #expect(event.intensity == .light)
    #expect(event.bursts == [SnoreBurst(startOffset: 0, endOffset: 3.0)])
    #expect(!machine.hasActiveSnoreEvent)
  }

  @Test func silenceDoesNotFinalizeWhileTheMelodyPlays() {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 60, from: &tick)
    var playing = Self.silence
    playing.isMelodyPlaying = true
    feed(&machine, playing, count: 300, from: &tick)
    #expect(machine.hasActiveSnoreEvent)
  }

  @Test(arguments: [(0.5, true), (1.0, false)])
  func eventsShorterThanTheMinimumAreDiscarded(minEventDuration: TimeInterval, kept: Bool) {
    var machine = machine(minEventDuration: minEventDuration, highConfidenceGate: 0)
    var tick = 0
    feed(&machine, Self.snoring, count: 16, from: &tick) // span 0.75 s
    let outputs = feed(&machine, Self.silence, count: 200, from: &tick)
    #expect(finalized(outputs).count == (kept ? 1 : 0))
    #expect(outputs.contains(.snoreEventDiscarded(id: Self.eventID, reason: .belowMinimumDuration)) == !kept)
  }

  /// Under 3 s, the mean classifier confidence must clear the high gate.
  @Test(arguments: [(Float(0.5), false), (0.6, true)])
  func shortEventsNeedTheHighConfidenceGate(confidence: Float, kept: Bool) {
    var machine = machine(highConfidenceGate: 0.55)
    var tick = 0
    feed(&machine, DetectionInput(db: -35, snoreConfidence: confidence, snoreState: .light), count: 40, from: &tick)
    let outputs = feed(&machine, Self.silence, count: 200, from: &tick)
    #expect(finalized(outputs).count == (kept ? 1 : 0))
    #expect(outputs.contains(.snoreEventDiscarded(id: Self.eventID, reason: .lowConfidenceShortEvent)) == !kept)
  }

  @Test func longEventsSkipTheConfidenceGate() {
    var machine = machine(highConfidenceGate: 0.99)
    var tick = 0
    feed(&machine, Self.snoring, count: 80, from: &tick) // span 3.95 s
    #expect(finalized(feed(&machine, Self.silence, count: 200, from: &tick)).count == 1)
  }

  @Test func intensityKeepsTheLoudestTierAndStatsAverage() throws {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 30, from: &tick)
    feed(&machine, DetectionInput(db: -15, snoreConfidence: 0.8, snoreState: .loud), count: 30, from: &tick)
    feed(&machine, Self.snoring, count: 10, from: &tick)
    let event = try #require(finalized(feed(&machine, Self.silence, count: 200, from: &tick)).first)
    #expect(event.intensity == .loud)
    #expect(event.peakDB == -15)
    #expect(event.averageDB > -35 && event.averageDB < -15)
  }

  @Test func sessionEndFinalizesWithoutWaitingForSilence() throws {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 80, from: &tick)
    let outputs = machine.finalizeActiveEvents(at: time(tick))
    #expect(finalized(outputs).count == 1)
    #expect(!machine.hasActiveSnoreEvent)
  }

  // MARK: - Snore Interrupter

  @Test func melodyStartClosesTheClipAndTheBurstButNotTheEvent() {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 3, from: &tick)
    #expect(machine.melodyDidStart(at: time(tick)) == [.eventClipClosed])
    #expect(machine.hasActiveSnoreEvent)
  }

  @Test func melodyStopEmitsTheGapOnlyAfterAStart() {
    var machine = machine()
    #expect(machine.melodyDidStop(at: t0).isEmpty)
    _ = machine.melodyDidStart(at: t0)
    #expect(machine.melodyDidStop(at: t0.addingTimeInterval(5)) == [.recordingGap(start: t0, duration: 5)])
  }

  /// Snoring resumes within the 3 s breathing delay: the gap counts and the
  /// event's span runs through it.
  @Test func snoringWithinTheBreathingDelayKeepsTheEventAcrossTheGap() throws {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 3, from: &tick)
    _ = machine.melodyDidStart(at: time(tick))
    tick += 100 // mic paused for 5 s: no samples
    _ = machine.melodyDidStop(at: time(tick))
    feed(&machine, Self.silence, count: 20, from: &tick)
    let resumed = feed(&machine, Self.snoring, count: 3, from: &tick)
    #expect(resumed.first == .snoringResumedAfterMelody)
    let event = try #require(finalized(feed(&machine, Self.silence, count: 200, from: &tick)).first)
    #expect(event.start == time(1))
    #expect(abs(event.duration - (time(126).timeIntervalSince(time(1)))) < 1e-6)
  }

  /// No snoring within the breathing delay: the event ends at the last
  /// pre-melody sample (here too short to keep).
  @Test func silenceThroughTheBreathingDelayCutsTheEventBeforeTheGap() {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 3, from: &tick)
    _ = machine.melodyDidStart(at: time(tick))
    tick += 100
    _ = machine.melodyDidStop(at: time(tick))
    let beforeDelay = feed(&machine, Self.silence, count: 59, from: &tick)
    #expect(beforeDelay.isEmpty)
    let outputs = feed(&machine, Self.silence, count: 1, from: &tick)
    #expect(outputs == [.snoreEventDiscarded(id: Self.eventID, reason: .belowMinimumDuration)])
  }

  @Test func sustainedSilenceStopsTheMelodyOnlyAfterItsMinimumPlayTime() {
    var machine = machine()
    var tick = 0
    feed(&machine, Self.snoring, count: 3, from: &tick)
    _ = machine.melodyDidStart(at: time(tick))
    var silenceWhilePlaying = Self.silence
    silenceWhilePlaying.isMelodyPlaying = true
    let early = feed(&machine, silenceWhilePlaying, count: 79, from: &tick) // 3.95 s
    #expect(!early.contains(.melodyStopRequested))
    #expect(feed(&machine, silenceWhilePlaying, count: 1, from: &tick) == [.melodyStopRequested])
  }

  // MARK: - Sleep talking

  @Test func speechBecomesAnEventAfterTheGap() throws {
    var machine = machine(sleepTalking: true)
    var tick = 0
    feed(&machine, Self.speech, count: 40, from: &tick)
    #expect(machine.hasActiveSpeechEvent)
    let outputs = feed(&machine, Self.silence, count: 200, from: &tick)
    let speech = try #require(outputs.compactMap { if case let .speechEventFinalized(e) = $0 { e } else { nil } }.first)
    #expect(speech.start == time(1))
    #expect(abs(speech.duration - 1.95) < 1e-6)
  }

  @Test func speechIsIgnoredWhenSleepTalkingIsOff() {
    var machine = machine(sleepTalking: false)
    var tick = 0
    feed(&machine, Self.speech, count: 40, from: &tick)
    #expect(!machine.hasActiveSpeechEvent)
  }

  @Test func utterancesUnderHalfASecondAreDropped() {
    var machine = machine(sleepTalking: true)
    var tick = 0
    feed(&machine, Self.speech, count: 10, from: &tick) // span 0.45 s
    #expect(machine.finalizeActiveEvents(at: time(tick)).isEmpty)
    #expect(!machine.hasActiveSpeechEvent)
  }

  @Test func snoringEndsTheSpeechEventAtThatSample() throws {
    var machine = machine(sleepTalking: true)
    var tick = 0
    feed(&machine, Self.speech, count: 40, from: &tick)
    let outputs = feed(&machine, Self.snoring, count: 1, from: &tick)
    guard case let .speechEventFinalized(speech) = try #require(outputs.first) else {
      Issue.record("expected the speech event first, got \(outputs)")
      return
    }
    #expect(abs(speech.duration - time(41).timeIntervalSince(time(1))) < 1e-6)
  }
}
