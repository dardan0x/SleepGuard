import Foundation
import SwiftData

/// Opens the app's on-disk store without ever deleting the user's data in a
/// shipped build.
///
/// A store that fails to open (a failed migration, a corrupt file) is left on
/// disk so a fixed build can open it again. The app then runs on an in-memory
/// store and tells the user. Only Debug builds may reset the store, because a
/// development schema change is the expected cause there.
public enum SleepGuardStore {
  public struct Opening {
    public let container: ModelContainer
    /// Why the on-disk store couldn't be opened. `nil` when it opened.
    public let failure: (any Error)?
  }

  /// Opens `configuration`. On failure, resets the store first when
  /// `allowDestructiveReset` is true (Debug only), otherwise falls back to an
  /// in-memory store and keeps the file.
  public static func open(_ configuration: ModelConfiguration, allowDestructiveReset: Bool) -> Opening {
    do {
      return try Opening(container: SleepGuardSchema.container(configuration), failure: nil)
    } catch {
      Log.storage.fault("Store failed to open: \(String(describing: error), privacy: .public)")
      if allowDestructiveReset {
        removeStoreFiles(at: configuration.url)
        if let container = try? SleepGuardSchema.container(configuration) {
          Log.storage.notice("Store reset after open failure (Debug only)")
          return Opening(container: container, failure: nil)
        }
      }
      do {
        let memory = try SleepGuardSchema.container(SleepGuardSchema.configuration(inMemory: true))
        return Opening(container: memory, failure: error)
      } catch {
        fatalError("Could not create an in-memory ModelContainer: \(error)")
      }
    }
  }

  /// Copies the store (and its `-wal` / `-shm` companions) next to itself as
  /// `<name>.bak` once per app version, before the store is opened, so a
  /// failed migration in a new version still leaves a copy written by the old
  /// one. Does nothing when there is no store yet or this version already
  /// backed it up.
  public static func backUpIfNeeded(storeURL: URL, appVersion: String) {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: storeURL.path) else {
      Log.storage.debug("No store to back up at \(storeURL.path)")
      return
    }
    let marker = storeURL.appendingPathExtension("bak-version")
    if (try? String(contentsOf: marker, encoding: .utf8)) == appVersion {
      Log.storage.debug("Store already backed up for \(appVersion, privacy: .public)")
      return
    }
    do {
      for (source, backup) in storeFiles(at: storeURL).map({ ($0, $0.appendingPathExtension("bak")) })
        where fileManager.fileExists(atPath: source.path)
      {
        try? fileManager.removeItem(at: backup)
        try fileManager.copyItem(at: source, to: backup)
      }
      try appVersion.write(to: marker, atomically: true, encoding: .utf8)
      Log.storage.notice("Store backed up for \(appVersion, privacy: .public)")
    } catch {
      Log.storage.error("Store backup failed: \(String(describing: error), privacy: .public)")
    }
  }

  private static func storeFiles(at url: URL) -> [URL] {
    [url, URL(fileURLWithPath: url.path + "-wal"), URL(fileURLWithPath: url.path + "-shm")]
  }

  private static func removeStoreFiles(at url: URL) {
    for file in storeFiles(at: url) {
      try? FileManager.default.removeItem(at: file)
    }
  }
}
