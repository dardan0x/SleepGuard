import Foundation
import Models

/// Tracks files belonging to the current unsaved sleep session.
/// On app relaunch or session discard, any tracked files are deleted so
/// orphaned clips / recordings don't accumulate on disk.
@MainActor
public final class PendingSessionStore {
  public static let shared = PendingSessionStore()

  private let defaultsKey = "pendingSessionRecord"
  private let defaults = UserDefaults.standard

  private init() {}

  // MARK: - Public API

  /// Register a new session as pending. Any previous pending session is cleaned up first.
  /// Pass the session audio filename only when a full-session raw file is being recorded.
  public func setPending(sessionID: UUID, sessionAudioFilename: String? = nil) {
    cleanupIfNeeded()
    var fileNames: [String] = []
    if let sessionAudioFilename {
      fileNames.append(sessionAudioFilename)
    }
    let record = PendingSessionRecord(sessionID: sessionID, fileNames: fileNames)
    save(record)
  }

  /// Append a filename to the pending record so it will be deleted if the session is discarded.
  public func addFile(_ filename: String) {
    guard var record = load() else { return }
    if !record.fileNames.contains(filename) {
      record.fileNames.append(filename)
      save(record)
    }
  }

  /// Remove the pending record so files are no longer tracked for cleanup.
  public func clearPending() {
    defaults.removeObject(forKey: defaultsKey)
  }

  /// Delete all tracked files for the pending session and clear the record.
  public func cleanupIfNeeded() {
    guard let record = load() else { return }
    for filename in record.fileNames {
      if let url = AudioFileURLResolver.resolve(filename) {
        try? FileManager.default.removeItem(at: url)
      }
    }
    clearPending()
  }

  // MARK: - Private

  private func load() -> PendingSessionRecord? {
    guard let data = defaults.data(forKey: defaultsKey) else { return nil }
    return try? JSONDecoder().decode(PendingSessionRecord.self, from: data)
  }

  private func save(_ record: PendingSessionRecord) {
    if let data = try? JSONEncoder().encode(record) {
      defaults.set(data, forKey: defaultsKey)
    }
  }
}

// MARK: - Data model

private struct PendingSessionRecord: Codable {
  let sessionID: UUID
  var fileNames: [String]
}
