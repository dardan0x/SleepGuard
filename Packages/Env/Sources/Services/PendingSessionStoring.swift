import Foundation
import Models

/// Tracks files of an in-progress session for crash cleanup. Fake: `FakePendingSessionStore`.
@MainActor
public protocol PendingSessionStoring: AnyObject {
  func setPending(sessionID: UUID, sessionAudioFilename: String?)
  func addFile(_ filename: String)
  func clearPending()
  func cleanupIfNeeded()
}
