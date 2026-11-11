import Foundation
import Testing
@testable import AudioEngine

/// `DetectionEngine` must decide exactly what the bare state machine decides,
/// however the messages are delivered (F22-T10).
struct DetectionEngineTests {
  private static let settings = DetectionReplayTests.settings

  /// Records every batch the engine performs, and answers with feedback.
  private actor Performer {
    private(set) var batches: [DetectionEngine.Batch] = []
    private let feedback: @Sendable (DetectionEngine.Batch) -> [DetectionEngine.Message]

    init(feedback: @escaping @Sendable (DetectionEngine.Batch) -> [DetectionEngine.Message] = { _ in [] }) {
      self.feedback = feedback
    }

    func perform(_ batch: DetectionEngine.Batch) -> [DetectionEngine.Message] {
      batches.append(batch)
      return feedback(batch)
    }

    var count: Int {
      batches.count
    }
  }

  /// How the producer hands messages to the stream.
  enum Delivery: CustomTestStringConvertible, CaseIterable {
    /// Everything queued before the engine runs.
    case burst
    /// One at a time, waiting for the engine after each (the app's rhythm).
    case paced
    /// Uneven chunks with suspensions and short sleeps in between.
    case jittered

    var testDescription: String {
      "\(self)"
    }
  }

  private static func run(
    _ messages: [DetectionEngine.Message],
    sessionEnd: Date?,
    delivery: Delivery,
    performer: Performer = Performer()) async throws -> ReplayTranscript.Run
  {
    let engine = DetectionEngine(settings: settings)
    let (stream, continuation) = DetectionEngine.makeStream()
    let task = Task { await engine.run(stream) { await performer.perform($0) } }

    func barrier() async {
      await withCheckedContinuation { continuation.yield(.barrier($0)) }
    }

    switch delivery {
    case .burst:
      messages.forEach { continuation.yield($0) }
    case .paced:
      for message in messages {
        continuation.yield(message)
        await barrier()
      }
    case .jittered:
      var index = 0
      var chunk = 1
      while index < messages.count {
        messages[index..<min(index + chunk, messages.count)].forEach { continuation.yield($0) }
        index += chunk
        chunk = chunk % 37 + 1
        if chunk.isMultiple(of: 5) {
          try await Task.sleep(for: .milliseconds(1))
        } else {
          await Task.yield()
        }
      }
    }
    await barrier()
    let sampleBatches = await performer.batches
    if let sessionEnd {
      continuation.yield(.finalize(at: sessionEnd))
    }
    continuation.finish()
    await task.value
    let all = await performer.batches
    return ReplayTranscript.Run(samples: sampleBatches, sessionEnd: Array(all.dropFirst(sampleBatches.count)))
  }

  // MARK: - Real recording

  /// The T9 goldens hold through the actor, under every delivery pattern.
  @Test(arguments: DetectionReplayTests.fixtures, Delivery.allCases)
  func engineReplayMatchesTheGolden(_ name: String, delivery: Delivery) async throws {
    let samples = try ReplayFixture.load(name)
    let run = try await Self.run(
      ReplayTranscript.sampleMessages(samples),
      sessionEnd: ReplayTranscript.endTime(samples),
      delivery: delivery)
    #expect(run.normalizingIDs() == ReplayTranscript.machineRun(samples, settings: Self.settings).normalizingIDs())
    // A recording run rewrites the goldens in the source tree; the bundled copies are stale.
    guard ProcessInfo.processInfo.environment["RECORD_REPLAY_GOLDENS"] != "1" else { return }
    let transcript = ReplayTranscript.render(name: name, samples: samples, settings: Self.settings, run: run)
    let difference = try ReplayTranscript.firstDifference(expected: ReplayFixture.golden(name), actual: transcript)
    #expect(difference == nil, "\(name) via engine (\(delivery)): \(difference ?? "")")
  }

  // MARK: - Melody feedback

  /// The melody starts on the first request. Its `melodyDidStart` must be
  /// applied before any sample that was already queued behind the request,
  /// exactly as the synchronous tracker applied it.
  @Test(arguments: Delivery.allCases)
  func melodyFeedbackIsAppliedBeforeQueuedSamples(delivery: Delivery) async throws {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    let snoring = DetectionInput(db: -35, snoreConfidence: 0.6, snoreState: .light)
    let messages: [DetectionEngine.Message] = (1...20).map { .sample(snoring, at: t0.addingTimeInterval(Double($0) * 0.05)) }

    let performer = Performer { batch in
      batch.outputs.contains(.melodyRequested) && batch.outputs.contains { if case .snoreEventStarted = $0 { true } else { false } }
        ? [.melodyDidStart(at: batch.time)]
        : []
    }
    let run = try await Self.run(messages, sessionEnd: nil, delivery: delivery, performer: performer)

    // Synchronous reference: the same feedback rule applied inline.
    var machine = DetectionStateMachine(settings: Self.settings)
    var expected: [DetectionEngine.Batch] = []
    for case let .sample(input, at) in messages {
      let outputs = machine.ingest(input, at: at)
      guard !outputs.isEmpty else { continue }
      expected.append(.init(outputs: outputs, time: at))
      if outputs.contains(where: { if case .snoreEventStarted = $0 { true } else { false } }) {
        expected.append(.init(outputs: machine.melodyDidStart(at: at), time: at))
      }
    }
    #expect(ReplayTranscript.Run(samples: run.samples).normalizingIDs() == ReplayTranscript.Run(samples: expected).normalizingIDs())
    // The clip closes right after the onset batch, at the onset sample's time.
    #expect(run.samples.dropFirst().first == .init(outputs: [.eventClipClosed], time: t0.addingTimeInterval(Double(3) * 0.05)))
  }

  // MARK: - Ordering and control messages

  /// A melody stop sent between two samples is applied between them.
  @Test func controlMessagesKeepTheirPlaceInTheStream() async throws {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    let messages: [DetectionEngine.Message] = [
      .melodyDidStart(at: t0),
      .sample(DetectionInput(db: -60, snoreState: .none), at: t0.addingTimeInterval(1)),
      .melodyDidStop(at: t0.addingTimeInterval(5)),
      .sample(DetectionInput(db: -60, snoreState: .none), at: t0.addingTimeInterval(5.05)),
    ]
    let run = try await Self.run(messages, sessionEnd: nil, delivery: .burst)
    #expect(run.samples == [
      .init(outputs: [.eventClipClosed], time: t0),
      .init(outputs: [.recordingGap(start: t0, duration: 5)], time: t0.addingTimeInterval(5)),
    ])
  }

  /// New settings apply from the next sample on.
  @Test func settingsChangeAppliesToLaterSamples() async throws {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    let snoring = DetectionInput(db: -35, snoreConfidence: 0.6, snoreState: .light)
    var messages: [DetectionEngine.Message] = (1...16).map { .sample(snoring, at: t0.addingTimeInterval(Double($0) * 0.05)) }
    var lenient = Self.settings
    lenient.minEventDuration = 0.5
    messages.append(.settings(lenient))
    let run = try await Self.run(messages, sessionEnd: t0.addingTimeInterval(0.8), delivery: .burst)
    // A 0.75 s event: dropped at the 1.0 s default, kept at 0.5 s.
    #expect(run.sessionEnd.first?.outputs.contains { if case .snoreEventFinalized = $0 { true } else { false } } == true)
  }

  /// A barrier resumes only after every earlier batch has been performed.
  @Test func barrierWaitsForEarlierBatches() async {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    let performer = Performer()
    let engine = DetectionEngine(settings: Self.settings)
    let (stream, continuation) = DetectionEngine.makeStream()
    let task = Task { await engine.run(stream) { await performer.perform($0) } }
    let snoring = DetectionInput(db: -35, snoreConfidence: 0.6, snoreState: .light)
    for tick in 1...10 {
      continuation.yield(.sample(snoring, at: t0.addingTimeInterval(Double(tick) * 0.05)))
    }
    await withCheckedContinuation { continuation.yield(.barrier($0)) }
    // Ticks 3–10 each produce a batch (onset, then one melody request per sample).
    #expect(await performer.count == 8)
    continuation.finish()
    await task.value
  }
}

extension ReplayTranscript.Run {
  /// Event IDs are random; renumber them in order of appearance so two runs compare.
  func normalizingIDs() -> Self {
    var numbers: [UUID: UUID] = [:]
    func id(_ original: UUID) -> UUID {
      if let mapped = numbers[original] { return mapped }
      let mapped = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", numbers.count + 1))!
      numbers[original] = mapped
      return mapped
    }
    func map(_ batch: DetectionEngine.Batch) -> DetectionEngine.Batch {
      .init(outputs: batch.outputs.map { output in
        switch output {
        case let .snoreEventStarted(original, start): .snoreEventStarted(id: id(original), start: start)
        case let .snoreEventDiscarded(original, reason): .snoreEventDiscarded(id: id(original), reason: reason)
        case let .snoreEventFinalized(event): .snoreEventFinalized(DetectedSnoreEvent(
            id: id(event.id),
            start: event.start,
            duration: event.duration,
            intensity: event.intensity,
            averageDB: event.averageDB,
            peakDB: event.peakDB,
            averageConfidence: event.averageConfidence,
            averageSpectralScore: event.averageSpectralScore,
            bursts: event.bursts))
        default: output
        }
      }, time: batch.time)
    }
    return Self(samples: samples.map(map), sessionEnd: sessionEnd.map(map))
  }
}
