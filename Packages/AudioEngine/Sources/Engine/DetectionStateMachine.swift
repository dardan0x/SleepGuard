import Foundation
import Models

/// One classified 50 ms sample, as the detection state machine sees it.
public struct DetectionInput: Sendable, Equatable {
  /// RMS level. Event loudness statistics use this, not the peak.
  public var db: Float
  public var spectralScore: Float
  public var snoreConfidence: Float
  /// The snore classifier's verdict for this sample (`SnoreDetector.classify`).
  public var snoreState: DetectionState
  /// The speech classifier's verdict for this sample (`SpeechDetector.classify`).
  public var isSpeech: Bool
  /// Whether the Snore Interrupter is playing when the sample arrives.
  public var isMelodyPlaying: Bool

  public init(
    db: Float,
    spectralScore: Float = 0,
    snoreConfidence: Float = 0,
    snoreState: DetectionState,
    isSpeech: Bool = false,
    isMelodyPlaying: Bool = false)
  {
    self.db = db
    self.spectralScore = spectralScore
    self.snoreConfidence = snoreConfidence
    self.snoreState = snoreState
    self.isSpeech = isSpeech
    self.isMelodyPlaying = isMelodyPlaying
  }
}

/// A snore event that passed every filter, ready to persist.
public struct DetectedSnoreEvent: Sendable, Equatable {
  public let id: UUID
  public let start: Date
  public let duration: TimeInterval
  public let intensity: SnoreIntensity
  public let averageDB: Double
  public let peakDB: Double
  public let averageConfidence: Double
  public let averageSpectralScore: Double
  /// Offsets from `start`. Empty when no burst closed.
  public let bursts: [SnoreBurst]
}

/// A sleep-talking event that passed the minimum duration, ready to persist.
public struct DetectedSpeechEvent: Sendable, Equatable {
  public let start: Date
  public let duration: TimeInterval
  public let averageDB: Double
  public let peakDB: Double
}

/// What the state machine asks its owner to do. Emitted in the order to perform them.
public enum DetectionOutput: Sendable, Equatable {
  public enum DiscardReason: Sendable, Equatable {
    case belowMinimumDuration
    case lowConfidenceShortEvent
  }

  /// A snore event began at `start` (backdated to the first sustained sample).
  /// Start recording its clip.
  case snoreEventStarted(id: UUID, start: Date)
  /// Sustained snoring: ask the Snore Interrupter to play. If it actually starts,
  /// report it back with `melodyDidStart(at:)`.
  case melodyRequested
  /// Sustained non-snoring after the melody's minimum play time: stop it.
  case melodyStopRequested
  /// The open event's clip must close now (the mic is about to pause).
  case eventClipClosed
  /// Snoring resumed within the breathing delay after a melody: the latest
  /// recording gap counts as snoring.
  case snoringResumedAfterMelody
  /// The melody ran from `start` for `duration`; record a recording gap.
  case recordingGap(start: Date, duration: TimeInterval)
  case snoreEventFinalized(DetectedSnoreEvent)
  /// The event was filtered out. Delete its clip.
  case snoreEventDiscarded(id: UUID, reason: DiscardReason)
  case speechEventFinalized(DetectedSpeechEvent)
}

/// The real-time snore / sleep-talking event state machine.
///
/// Pure value type: no clock (every call takes the time), no singletons, no
/// SwiftData, no audio. Feed it one classified sample per 50 ms tick with
/// `ingest(_:at:)` and perform the returned outputs in order;
/// `RealtimeDetectionTracker` is that adapter in the app.
///
/// The Snore Interrupter is a feedback loop: `ingest` may emit
/// `.melodyRequested`, and the owner reports back `melodyDidStart(at:)` (if the
/// melody actually started) and `melodyDidStop(at:)` (whenever it stops).
public struct DetectionStateMachine: Sendable {
  public struct Settings: Sendable, Equatable {
    /// Snore events shorter than this are discarded (sensitivity-dependent).
    public var minEventDuration: TimeInterval
    /// Events under 3 s need at least this mean classifier confidence.
    public var highConfidenceGate: Float
    public var detectSleepTalking: Bool

    public init(minEventDuration: TimeInterval, highConfidenceGate: Float, detectSleepTalking: Bool) {
      self.minEventDuration = minEventDuration
      self.highConfidenceGate = highConfidenceGate
      self.detectSleepTalking = detectSleepTalking
    }
  }

  // MARK: - Tuning (unchanged from the pre-extraction tracker)

  /// Silence that ends an event.
  static let eventGapThreshold: TimeInterval = 10.0
  /// Consecutive snoring samples (≈150 ms at 20 Hz) before an event starts.
  /// Filters transient sounds (bed creaks, taps, notifications).
  static let requiredConsecutiveSamples = 3
  /// Consecutive non-snoring samples before the melody may stop.
  static let requiredNonSnoreSamplesToStop = 3
  /// The melody plays at least this long before non-snoring can stop it.
  static let melodyMinPlayDuration: TimeInterval = 4.0
  /// After the melody stops, snoring must resume within this delay for the gap
  /// to count as snoring time.
  static let postMelodyBreathingDelay: TimeInterval = 3.0
  /// Events shorter than this must clear the high-confidence gate.
  static let shortEventThreshold: TimeInterval = 3.0
  /// Spectral-only short events need this mean spectral score.
  static let shortEventSpectralGate = 0.65
  static let requiredConsecutiveSpeechSamples = 3
  /// Sleep-talking utterances shorter than this are discarded.
  static let minSpeechEventDuration: TimeInterval = 0.5
  static let sampleInterval: TimeInterval = 0.05

  public var settings: Settings
  private let makeID: @Sendable () -> UUID

  // MARK: - Snore event state

  private var activeEventStart: Date?
  private var activeEventID: UUID?
  private var activeEventIntensity: SnoreIntensity?
  private var activeEventDBSum: Double = 0
  private var activeEventDBCount = 0
  private var activeEventPeakDB: Double = 0
  private var activeEventConfidenceSum: Double = 0
  private var activeEventConfidenceCount = 0
  private var activeEventSpectralSum: Double = 0
  private var activeEventSpectralCount = 0
  private var lastSnoringSampleTime: Date?
  private var consecutiveSnoreSamples = 0
  private var consecutiveNonSnoreSamples = 0
  private var activeBurstStart: Date?
  private var completedBursts: [(start: Date, end: Date)] = []

  // MARK: - Melody state

  private var melodyStartTime: Date?
  private var melodyResumeTime: Date?
  private var postMelodySnoringDetected = false

  // MARK: - Speech event state

  private var activeSpeechEventStart: Date?
  private var activeSpeechEventDBSum: Double = 0
  private var activeSpeechEventDBCount = 0
  private var activeSpeechEventPeakDB: Double = 0
  private var lastSpeechSampleTime: Date?
  private var consecutiveSpeechSamples = 0

  /// `makeID` names new snore events; tests pass a deterministic sequence.
  public init(settings: Settings, makeID: @escaping @Sendable () -> UUID = { UUID() }) {
    self.settings = settings
    self.makeID = makeID
  }

  public var hasActiveSnoreEvent: Bool {
    activeEventStart != nil
  }

  public var hasActiveSpeechEvent: Bool {
    activeSpeechEventStart != nil
  }

  // MARK: - Ingest

  public mutating func ingest(_ input: DetectionInput, at now: Date) -> [DetectionOutput] {
    var outputs: [DetectionOutput] = []
    if input.snoreState != .none {
      ingestSnoring(input, at: now, into: &outputs)
    } else {
      ingestNonSnoring(input, at: now, into: &outputs)
    }
    return outputs
  }

  private mutating func ingestSnoring(_ input: DetectionInput, at now: Date, into outputs: inout [DetectionOutput]) {
    // Snoring takes priority: end any active speech event right now.
    if activeSpeechEventStart != nil {
      finalizeSpeechEvent(endTime: now, fallback: now, into: &outputs)
    }

    consecutiveSnoreSamples += 1
    consecutiveNonSnoreSamples = 0
    // During the post-melody breathing delay, don't extend the event until
    // sustained snoring confirms it; transients shouldn't make the gap count.
    if melodyResumeTime == nil || postMelodySnoringDetected {
      lastSnoringSampleTime = now
    }
    guard consecutiveSnoreSamples >= Self.requiredConsecutiveSamples else { return }

    let db = Double(input.db)
    if activeEventStart == nil {
      // Backdate to when sustained detection began.
      let backdate = TimeInterval(Self.requiredConsecutiveSamples - 1) * Self.sampleInterval
      let start = now.addingTimeInterval(-backdate)
      let id = makeID()
      activeEventStart = start
      activeEventID = id
      activeEventDBSum = db
      activeEventDBCount = 1
      activeEventPeakDB = db
      activeEventConfidenceSum = input.snoreConfidence > 0 ? Double(input.snoreConfidence) : 0
      activeEventConfidenceCount = input.snoreConfidence > 0 ? 1 : 0
      activeEventSpectralSum = input.spectralScore > 0 ? Double(input.spectralScore) : 0
      activeEventSpectralCount = input.spectralScore > 0 ? 1 : 0
      activeEventIntensity = SnoreIntensity(input.snoreState)
      activeBurstStart = start
      outputs.append(.snoreEventStarted(id: id, start: start))
      outputs.append(.melodyRequested)
      return
    }

    activeEventDBSum += db
    activeEventDBCount += 1
    activeEventPeakDB = max(activeEventPeakDB, db)
    if input.snoreConfidence > 0 {
      activeEventConfidenceSum += Double(input.snoreConfidence)
      activeEventConfidenceCount += 1
    }
    if input.spectralScore > 0 {
      activeEventSpectralSum += Double(input.spectralScore)
      activeEventSpectralCount += 1
    }
    let intensity = SnoreIntensity(input.snoreState)
    if intensity.rank > (activeEventIntensity ?? .quiet).rank {
      activeEventIntensity = intensity
    }
    // A new burst after a brief pause.
    if activeBurstStart == nil {
      activeBurstStart = now
    }
    // Sustained snoring within the breathing delay: the melody gap counts.
    if melodyResumeTime != nil, !postMelodySnoringDetected {
      postMelodySnoringDetected = true
      lastSnoringSampleTime = now
      outputs.append(.snoringResumedAfterMelody)
    }
    // The event stays open across melody gaps, but sustained snoring after a
    // melody should still play it again.
    outputs.append(.melodyRequested)
  }

  private mutating func ingestNonSnoring(_ input: DetectionInput, at now: Date, into outputs: inout [DetectionOutput]) {
    // The breathing delay expired without snoring: end the event at the last
    // pre-melody snoring sample so the gap isn't counted.
    if let resumeTime = melodyResumeTime,
       activeEventStart != nil,
       !postMelodySnoringDetected,
       now.timeIntervalSince(resumeTime) >= Self.postMelodyBreathingDelay
    {
      melodyResumeTime = nil
      finalizeSnoreEvent(fallback: now, into: &outputs)
      return
    }

    consecutiveSnoreSamples = 0
    consecutiveNonSnoreSamples += 1
    if let burstStart = activeBurstStart {
      completedBursts.append((start: burstStart, end: now))
      activeBurstStart = nil
    }
    // Not while the melody plays: the mic is paused and levels are stale.
    if let lastSnore = lastSnoringSampleTime,
       activeEventStart != nil,
       now.timeIntervalSince(lastSnore) >= Self.eventGapThreshold,
       !input.isMelodyPlaying
    {
      finalizeSnoreEvent(fallback: now, into: &outputs)
    }

    if consecutiveNonSnoreSamples >= Self.requiredNonSnoreSamplesToStop, input.isMelodyPlaying {
      let minDurationMet = melodyStartTime.map { now.timeIntervalSince($0) >= Self.melodyMinPlayDuration } ?? true
      guard minDurationMet else { return }
      outputs.append(.melodyStopRequested)
      consecutiveNonSnoreSamples = 0
    }

    guard settings.detectSleepTalking else { return }
    if input.isSpeech {
      consecutiveSpeechSamples += 1
      lastSpeechSampleTime = now
      guard consecutiveSpeechSamples >= Self.requiredConsecutiveSpeechSamples else { return }
      let db = Double(input.db)
      if activeSpeechEventStart == nil {
        let backdate = TimeInterval(Self.requiredConsecutiveSpeechSamples - 1) * Self.sampleInterval
        activeSpeechEventStart = now.addingTimeInterval(-backdate)
        activeSpeechEventDBSum = db
        activeSpeechEventDBCount = 1
        activeSpeechEventPeakDB = db
      } else {
        activeSpeechEventDBSum += db
        activeSpeechEventDBCount += 1
        activeSpeechEventPeakDB = max(activeSpeechEventPeakDB, db)
      }
    } else {
      consecutiveSpeechSamples = 0
      if let lastSpeech = lastSpeechSampleTime,
         activeSpeechEventStart != nil,
         now.timeIntervalSince(lastSpeech) >= Self.eventGapThreshold
      {
        finalizeSpeechEvent(endTime: nil, fallback: now, into: &outputs)
      }
    }
  }

  // MARK: - Melody feedback

  /// The melody requested by `ingest` actually started (the mic is about to
  /// pause). Closes the clip and the burst; the event stays open so its span
  /// covers the gap.
  public mutating func melodyDidStart(at now: Date) -> [DetectionOutput] {
    melodyStartTime = now
    if let burstStart = activeBurstStart {
      completedBursts.append((start: burstStart, end: lastSnoringSampleTime ?? now))
      activeBurstStart = nil
    }
    consecutiveSnoreSamples = 0
    consecutiveNonSnoreSamples = 0
    return [.eventClipClosed]
  }

  /// The melody stopped, for any reason. Emits the recording gap and starts the
  /// breathing delay if an event is open.
  public mutating func melodyDidStop(at now: Date) -> [DetectionOutput] {
    guard let start = melodyStartTime else { return [] }
    melodyStartTime = nil
    if activeEventStart != nil {
      melodyResumeTime = now
      postMelodySnoringDetected = false
    }
    // Stale pause-time samples must not stop the next melody immediately.
    consecutiveNonSnoreSamples = 0
    return [.recordingGap(start: start, duration: now.timeIntervalSince(start))]
  }

  // MARK: - Session end

  /// Ends any open snore and speech events (session stop). `now` stands in for
  /// timestamps that were never set.
  public mutating func finalizeActiveEvents(at now: Date) -> [DetectionOutput] {
    var outputs: [DetectionOutput] = []
    if activeEventStart != nil {
      finalizeSnoreEvent(fallback: now, into: &outputs)
    }
    if activeSpeechEventStart != nil {
      finalizeSpeechEvent(endTime: nil, fallback: now, into: &outputs)
    }
    return outputs
  }

  // MARK: - Finalization

  private mutating func finalizeSnoreEvent(fallback now: Date, into outputs: inout [DetectionOutput]) {
    guard let start = activeEventStart else { return }
    if let burstStart = activeBurstStart {
      completedBursts.append((start: burstStart, end: lastSnoringSampleTime ?? now))
      activeBurstStart = nil
    }
    let bursts = completedBursts.map {
      SnoreBurst(startOffset: $0.start.timeIntervalSince(start), endOffset: $0.end.timeIntervalSince(start))
    }
    let span = (lastSnoringSampleTime ?? now).timeIntervalSince(start)
    let id = activeEventID ?? makeID()

    guard span >= settings.minEventDuration else {
      outputs.append(.snoreEventDiscarded(id: id, reason: .belowMinimumDuration))
      clearSnoreEvent()
      return
    }

    let averageConfidence = activeEventConfidenceCount > 0 ? activeEventConfidenceSum / Double(activeEventConfidenceCount) : 0
    let averageSpectralScore = activeEventSpectralCount > 0 ? activeEventSpectralSum / Double(activeEventSpectralCount) : 0
    // Short events need high confidence: the ML gate when the classifier
    // contributed, a stronger spectral score otherwise.
    if span < Self.shortEventThreshold {
      let passes = activeEventConfidenceCount > 0
        ? averageConfidence >= Double(settings.highConfidenceGate)
        : averageSpectralScore >= Self.shortEventSpectralGate
      guard passes else {
        outputs.append(.snoreEventDiscarded(id: id, reason: .lowConfidenceShortEvent))
        clearSnoreEvent()
        return
      }
    }

    outputs.append(.snoreEventFinalized(DetectedSnoreEvent(
      id: id,
      start: start,
      duration: span,
      intensity: activeEventIntensity ?? .quiet,
      averageDB: activeEventDBCount > 0 ? activeEventDBSum / Double(activeEventDBCount) : 0,
      peakDB: activeEventPeakDB,
      averageConfidence: averageConfidence,
      averageSpectralScore: averageSpectralScore,
      bursts: bursts)))
    clearSnoreEvent()
    melodyResumeTime = nil
    postMelodySnoringDetected = false
  }

  private mutating func finalizeSpeechEvent(endTime: Date?, fallback now: Date, into outputs: inout [DetectionOutput]) {
    guard let start = activeSpeechEventStart else { return }
    let span = (endTime ?? lastSpeechSampleTime ?? now).timeIntervalSince(start)
    if span >= Self.minSpeechEventDuration {
      outputs.append(.speechEventFinalized(DetectedSpeechEvent(
        start: start,
        duration: span,
        averageDB: activeSpeechEventDBCount > 0 ? activeSpeechEventDBSum / Double(activeSpeechEventDBCount) : 0,
        peakDB: activeSpeechEventPeakDB)))
    }
    activeSpeechEventStart = nil
    activeSpeechEventDBSum = 0
    activeSpeechEventDBCount = 0
    activeSpeechEventPeakDB = 0
  }

  /// Clears the open event and its bursts. Melody state is the caller's call:
  /// a discard deliberately leaves it as it was.
  private mutating func clearSnoreEvent() {
    activeEventStart = nil
    activeEventID = nil
    activeEventIntensity = nil
    activeEventDBSum = 0
    activeEventDBCount = 0
    activeEventPeakDB = 0
    activeEventConfidenceSum = 0
    activeEventConfidenceCount = 0
    activeEventSpectralSum = 0
    activeEventSpectralCount = 0
    completedBursts.removeAll()
  }
}

private extension SnoreIntensity {
  init(_ state: DetectionState) {
    switch state {
    case .quiet, .none: self = .quiet
    case .light: self = .light
    case .loud: self = .loud
    case .epic: self = .epic
    }
  }

  var rank: Int {
    switch self {
    case .quiet: 0
    case .light: 1
    case .loud: 2
    case .epic: 3
    }
  }
}
