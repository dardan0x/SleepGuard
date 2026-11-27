import AudioEngine
public import Foundation
public import Models
public import SleepStore

/// Every audio file that belongs to a night: event clips, the raw recording
/// and its classification log (found by the night's id). Read it
/// while `session.events` is still available, before the session is deleted.
@MainActor
public func sessionFileURLs(_ session: NightRecord) -> [URL] {
  let eventClips = session.events.compactMap { AudioFileURLResolver.resolve($0.clipFileName) }
  let sessionFiles = [session.rawAudioFileName, session.rawLogFileName]
    .compactMap { AudioFileURLResolver.resolve($0) }
  return eventClips + sessionFiles
}

/// Removes files, ignoring ones that are already gone.
public func removeFiles(_ urls: [URL]) {
  for url in urls {
    try? FileManager.default.removeItem(at: url)
  }
}

/// Deletes all audio files associated with a sleep session.
/// Call this **before** `modelContext.delete(session)` to avoid orphans on disk.
@MainActor
public func deleteSessionFiles(_ session: NightRecord) {
  removeFiles(sessionFileURLs(session))
}
