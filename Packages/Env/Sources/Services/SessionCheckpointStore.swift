import Foundation
public import Models
import os

/// Persists a recovery snapshot of the in-progress session to disk during
/// recording. If the app dies mid-session (crash / OOM / background kill), the
/// snapshot lets the session be reconstructed and offered to the user on the
/// next launch instead of being lost. Cleared once the session is saved or
/// discarded.
///
/// Writes leave the main actor: detection's `perform` hands the snapshot over
/// and returns, and `CheckpointWriter` encodes and writes it, keeping only the
/// latest when writes come in bursts. `clear()` stays synchronous, so a saved
/// night is never offered again after a kill. A sequence gate stops a write
/// still in flight from bringing back a cleared file.
@MainActor
public final class SessionCheckpointStore: SessionCheckpointStoring {
  public static let shared = SessionCheckpointStore()

  private let recoveryURL: URL
  /// The lowest write sequence still allowed to reach disk; `clear()` raises it.
  private let gate = OSAllocatedUnfairLock(initialState: 0)
  private let writer: CheckpointWriter
  private var sequence = 0
  private var lastWrite: Task<Void, Never>?

  public init() {
    recoveryURL = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("session_recovery.json")
    writer = CheckpointWriter(url: recoveryURL, gate: gate)
  }

  /// Hands the snapshot to the writer and returns at once.
  public func write(_ snapshot: SessionRecoverySnapshot) {
    sequence += 1
    let sequence = sequence
    let writer = writer
    lastWrite = Task { await writer.submit(snapshot, sequence: sequence) }
  }

  /// Returns the persisted snapshot if one exists and holds recoverable data.
  public func loadIfPresent() -> SessionRecoverySnapshot? {
    guard FileManager.default.fileExists(atPath: recoveryURL.path) else { return nil }
    do {
      let data = try Data(contentsOf: recoveryURL)
      let snapshot = try JSONDecoder().decode(SessionRecoverySnapshot.self, from: data)
      return snapshot.isRecoverable ? snapshot : nil
    } catch {
      Log.session.error("Checkpoint unreadable, night not recoverable: \(String(describing: error), privacy: .public)")
      return nil
    }
  }

  /// Removes the recovery file now. Called after the session is saved or
  /// discarded. Writes submitted before this never reach disk.
  public func clear() {
    sequence += 1
    let sequence = sequence
    let url = recoveryURL
    gate.withLock { lowest in
      lowest = sequence
      try? FileManager.default.removeItem(at: url)
    }
  }

  /// Waits until the latest write is on disk (tests).
  func flush() async {
    await lastWrite?.value
    await writer.drain()
  }

  /// How many times the writer touched the disk (tests).
  var diskWrites: Int {
    get async { await writer.diskWrites }
  }
}

/// Encodes and writes snapshots off the main actor. A burst of writes collapses
/// to the latest: a new snapshot replaces one still waiting, and an older one
/// arriving late is ignored.
actor CheckpointWriter {
  private let url: URL
  private let gate: OSAllocatedUnfairLock<Int>
  private var pending: (sequence: Int, snapshot: SessionRecoverySnapshot)?
  private var newestSequence = 0
  private var drainScheduled = false
  private(set) var diskWrites = 0

  init(url: URL, gate: OSAllocatedUnfairLock<Int>) {
    self.url = url
    self.gate = gate
  }

  func submit(_ snapshot: SessionRecoverySnapshot, sequence: Int) {
    guard sequence > newestSequence else { return }
    newestSequence = sequence
    pending = (sequence, snapshot)
    guard !drainScheduled else { return }
    drainScheduled = true
    Task { await self.drain() }
  }

  /// Writes the waiting snapshot, if any. `.atomic` writes to a temp file and
  /// renames, so a crash mid-write leaves the previous good snapshot intact.
  func drain() {
    drainScheduled = false
    guard let (sequence, snapshot) = pending else { return }
    pending = nil
    do {
      let data = try JSONEncoder().encode(snapshot)
      let url = url
      let wrote = try gate.withLock { lowest -> Bool in
        guard sequence >= lowest else { return false }
        try data.write(to: url, options: .atomic)
        return true
      }
      if wrote { diskWrites += 1 }
    } catch {
      Log.session.error("Checkpoint write failed: \(String(describing: error), privacy: .public)")
    }
  }
}
