import Foundation
import Models

/// Persists a recovery snapshot of the in-progress session to disk during
/// recording. If the app dies mid-session (crash / OOM / background kill), the
/// snapshot lets the session be reconstructed and offered to the user on the
/// next launch instead of being lost. Cleared once the session is saved or
/// discarded.
@MainActor
public final class SessionCheckpointStore: SessionCheckpointStoring {
  public static let shared = SessionCheckpointStore()

  private let fileName = "session_recovery.json"

  public init() {}

  private var recoveryURL: URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(fileName)
  }

  /// Atomically writes the snapshot. `.atomic` writes to a temp file and renames,
  /// so a crash mid-write leaves the previous good snapshot intact.
  public func write(_ snapshot: SessionRecoverySnapshot) {
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    try? data.write(to: recoveryURL, options: .atomic)
  }

  /// Returns the persisted snapshot if one exists and holds recoverable data.
  public func loadIfPresent() -> SessionRecoverySnapshot? {
    guard let data = try? Data(contentsOf: recoveryURL),
          let snapshot = try? JSONDecoder().decode(SessionRecoverySnapshot.self, from: data),
          snapshot.isRecoverable
    else { return nil }
    return snapshot
  }

  /// Removes the recovery file. Called after the session is saved or discarded.
  public func clear() {
    try? FileManager.default.removeItem(at: recoveryURL)
  }
}
