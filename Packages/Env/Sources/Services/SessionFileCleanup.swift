import Foundation
import Models
import AudioEngine

/// Deletes all audio files associated with a sleep session.
/// Call this **before** `modelContext.delete(session)` to avoid orphans on disk.
@MainActor
public func deleteSessionFiles(_ session: SleepSession) {
  let fm = FileManager.default

  // Delete per-event clips
  if let events = session.events {
    for event in events {
      if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
        try? fm.removeItem(at: url)
      }
    }
  }

  // Delete legacy full session audio (pre-clip sessions)
  if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
    try? fm.removeItem(at: url)
  }

  // Delete raw full session archive
  if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
    try? fm.removeItem(at: url)
  }

  // Delete raw classification log
  if let url = AudioFileURLResolver.resolve(session.rawLogFileURL) {
    try? fm.removeItem(at: url)
  }
}
