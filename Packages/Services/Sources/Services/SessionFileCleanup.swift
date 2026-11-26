import AudioEngine
public import Foundation
public import Models

/// Every audio file that belongs to a sleep session: event clips, legacy full
/// session audio, the raw archive and the raw classification log. Read it
/// while `session.events` is still available, before the session is deleted.
@MainActor
public func sessionFileURLs(_ session: SleepSession) -> [URL] {
  let eventClips = (session.events ?? []).compactMap { AudioFileURLResolver.resolve($0.audioFileURL) }
  let sessionFiles = [session.audioFileURL, session.rawAudioFileURL, session.rawLogFileURL]
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
public func deleteSessionFiles(_ session: SleepSession) {
  removeFiles(sessionFileURLs(session))
}
