import Foundation

/// Runs `DetectionStateMachine` on its own actor, fed by one ordered
/// `AsyncStream` (F22-T10, ADR 0003).
///
/// Everything that changes detection state is a `Message` in that one stream:
/// samples, melody start/stop, settings changes and the session-end flush. Each
/// carries the time it was observed at its source, and the engine handles them
/// strictly in arrival order. So a melody stop that happened before a sample is
/// always applied before it, whichever task delivered it.
///
/// Outputs go back to the caller through `perform`, one `Batch` per message
/// that produced any. The engine awaits each batch before the next message,
/// so side effects happen in order and a slow main actor slows the engine
/// rather than reordering it.
///
/// The Snore Interrupter is a feedback loop: when a batch contains
/// `.melodyRequested` and the melody actually starts, `perform` returns
/// `.melodyDidStart(at:)`. The engine applies returned messages *before* the
/// next queued one, exactly as the synchronous tracker did, so samples that
/// were already queued can't slip in between.
public actor DetectionEngine {
  public enum Message: Sendable {
    /// A classified sample, timestamped when it was taken.
    case sample(DetectionInput, at: Date)
    case melodyDidStart(at: Date)
    case melodyDidStop(at: Date)
    /// Applies from the next message on.
    case settings(DetectionStateMachine.Settings)
    /// Session end: finalizes any open snore and speech events.
    case finalize(at: Date)
    /// Resumes once every earlier message has been handled and its batch
    /// performed. Lets callers (and tests) wait for the engine to catch up.
    case barrier(CheckedContinuation<Void, Never>)
  }

  /// The outputs of one message, in the order to perform them.
  public struct Batch: Sendable, Equatable {
    public let outputs: [DetectionOutput]
    /// The source time of the message that produced them.
    public let time: Date
  }

  public typealias Perform = @Sendable (Batch) async -> [Message]

  private var machine: DetectionStateMachine
  private var isRunning = false

  public init(settings: DetectionStateMachine.Settings, makeID: @escaping @Sendable () -> UUID = { UUID() }) {
    machine = DetectionStateMachine(settings: settings, makeID: makeID)
  }

  /// A stream for `run(_:perform:)`.
  ///
  /// Unbounded on purpose. A bounded `.bufferingNewest` policy would drop the
  /// oldest messages under backpressure, and a dropped `.melodyDidStop` or
  /// `.finalize` corrupts the session, not just one sample. At 20 Hz with a
  /// consumer that takes microseconds per message, the queue stays empty in
  /// practice; see ADR 0003.
  public static func makeStream() -> (stream: AsyncStream<Message>, continuation: AsyncStream<Message>.Continuation) {
    AsyncStream.makeStream(of: Message.self, bufferingPolicy: .unbounded)
  }

  /// Handles messages until the stream finishes. Call once per engine.
  public func run(_ messages: AsyncStream<Message>, perform: Perform) async {
    precondition(!isRunning, "DetectionEngine.run(_:perform:) called twice")
    isRunning = true
    for await message in messages {
      await handle(message, perform: perform)
    }
  }

  private func handle(_ message: Message, perform: Perform) async {
    let time: Date
    let outputs: [DetectionOutput]
    switch message {
    case let .sample(input, at):
      time = at
      outputs = machine.ingest(input, at: at)
    case let .melodyDidStart(at):
      time = at
      outputs = machine.melodyDidStart(at: at)
    case let .melodyDidStop(at):
      time = at
      outputs = machine.melodyDidStop(at: at)
    case let .settings(settings):
      machine.settings = settings
      return
    case let .finalize(at):
      time = at
      outputs = machine.finalizeActiveEvents(at: at)
    case let .barrier(continuation):
      continuation.resume()
      return
    }
    guard !outputs.isEmpty else { return }
    // Feedback (the melody started) is applied before the next queued message.
    for feedback in await perform(Batch(outputs: outputs, time: time)) {
      await handle(feedback, perform: perform)
    }
  }
}
