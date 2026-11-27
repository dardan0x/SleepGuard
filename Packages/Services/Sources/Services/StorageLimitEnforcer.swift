import Config
import FactoryKit
import Foundation
import Models
import SleepCore
public import SwiftData
import SleepFiles
import SleepLogging
import SleepStore

/// Report returned after running storage cleanup.
public struct CleanupReport: Sendable {
  public var filesRemoved: Int
  public var bytesRemoved: Int64
  public var sessionsAffected: Int
  public var dayLimitSessions: Int
  public var sizeLimitSessions: Int

  public init(
    filesRemoved: Int = 0,
    bytesRemoved: Int64 = 0,
    sessionsAffected: Int = 0,
    dayLimitSessions: Int = 0,
    sizeLimitSessions: Int = 0)
  {
    self.filesRemoved = filesRemoved
    self.bytesRemoved = bytesRemoved
    self.sessionsAffected = sessionsAffected
    self.dayLimitSessions = dayLimitSessions
    self.sizeLimitSessions = sizeLimitSessions
  }
}

/// Nonisolated plan so file I/O can run off the main actor.
private struct CleanupPlan: Sendable {
  var fileURLs: [URL]
  var sessionsAffected: Int
}

/// Enforces user-configured storage limits by deleting oldest audio files
/// while preserving session metadata in SwiftData.
///
/// File I/O is performed off the main actor so launch and save are not blocked.
public final class StorageLimitEnforcer: Sendable, StorageLimitEnforcing {
  public static let shared = StorageLimitEnforcer()

  public init() {}

  /// Runs both size-based and day-based cleanup according to user preferences.
  /// Returns a report describing what was removed.
  @MainActor
  @discardableResult
  public func enforceLimits(modelContext: ModelContext) async -> CleanupReport {
    // Resolved here, not stored: this type is `Sendable` and can't hold the
    // main-actor preferences store. Tests use the explicit-limits overload.
    let prefs = Container.shared.userPreferences()
    return await enforceLimits(
      modelContext: modelContext,
      maxDays: prefs.limitDaysEnabled ? prefs.maxDays : nil,
      maxMB: prefs.limitStorageEnabled ? prefs.storageLimitMB : nil)
  }

  /// Same as above with explicit limits (`nil` = that limit is off), so tests
  /// don't depend on `UserDefaults`. `inProgress` is the night being
  /// recorded, whose files no saved night names yet (`nil`: the checkpoint's).
  @MainActor
  @discardableResult
  func enforceLimits(
    modelContext: ModelContext,
    maxDays: Int?,
    maxMB: Int?,
    inProgress: Night? = Container.shared.sessionCheckpointStore().loadIfPresent()) async -> CleanupReport
  {
    let sessions: [NightRecord]
    do {
      sessions = try modelContext.fetch(FetchDescriptor<NightRecord>(sortBy: [SortDescriptor(\.start)]))
    } catch {
      Log.storage.error("Session fetch failed, cleanup skipped: \(String(describing: error), privacy: .public)")
      return CleanupReport()
    }

    // SleepGuardShared's StorageSweep decides, as in SleepGuardUIKitWay: which
    // nights lose their audio (older than the day limit, then the oldest over
    // the size limit) and which files in the clips folder nothing names.
    let folder = ClipFolder(directory: AudioFileURLResolver.directory)
    let nights = sessions.map { nightFiles(for: $0, modelContext: modelContext) }
    let allFiles = folder.allFileNames()
    let sweep = StorageSweep.make(
      nights: nights, sizes: folder.sizes(of: allFiles), allFiles: allFiles, inProgress: inProgress, now: Date(),
      maxDays: maxDays, maxMB: maxMB)

    let byID = Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    func clear(_ ids: [UUID]) -> CleanupPlan {
      var urls: [URL] = []
      var affected = 0
      for id in ids {
        guard let session = byID[id] else { continue }
        let sessionURLs = collectAndClearURLs(for: session, modelContext: modelContext)
        if !sessionURLs.isEmpty {
          urls.append(contentsOf: sessionURLs)
          affected += 1
        }
      }
      return CleanupPlan(fileURLs: urls, sessionsAffected: affected)
    }
    let dayPlan = clear(sweep.plan.dayLimited)
    let sizePlan = clear(sweep.plan.sizeLimited)
    let leftoverPlan = CleanupPlan(fileURLs: sweep.leftovers.map(folder.directory.appendingPathComponent), sessionsAffected: 0)

    // Save URL clears immediately so the model is consistent even if
    // background file deletion is slow or fails.
    do {
      try modelContext.save()
    } catch {
      Log.storage.error("Failed to save context after clearing URLs: \(String(describing: error), privacy: .public)")
    }

    // Perform all file deletions off the main actor.
    let dayReport = await deleteFiles(plan: dayPlan)
    let sizeReport = await deleteFiles(plan: sizePlan)
    let leftoverReport = await deleteFiles(plan: leftoverPlan)

    let report = CleanupReport(
      filesRemoved: dayReport.filesRemoved + sizeReport.filesRemoved + leftoverReport.filesRemoved,
      bytesRemoved: dayReport.bytesRemoved + sizeReport.bytesRemoved + leftoverReport.bytesRemoved,
      sessionsAffected: dayReport.sessionsAffected + sizeReport.sessionsAffected,
      dayLimitSessions: dayReport.sessionsAffected,
      sizeLimitSessions: sizeReport.sessionsAffected)

    Log.storage.info("Cleanup complete — \(report.filesRemoved) file(s), \(report.bytesRemoved / 1_024 / 1_024) MB, \(report.sessionsAffected) session(s), \(leftoverReport.filesRemoved) leftover(s)")
    return report
  }

  /// A night's files as SleepCore's `NightFiles`: its events' clips and its
  /// raw recording and log (found by the night's id).
  @MainActor
  private func nightFiles(for session: NightRecord, modelContext: ModelContext) -> NightFiles {
    let names = fetchEvents(for: session, modelContext: modelContext).compactMap(\.clipFileName)
      + [session.rawAudioFileName, session.rawLogFileName].compactMap(\.self)
    return NightFiles(
      id: session.id, start: session.start,
      clipFileNames: Array(Set(names.map { ($0 as NSString).lastPathComponent })))
  }

  // MARK: - Event fetching (avoids faulting corrupted relationships)

  @MainActor
  private func fetchEvents(for session: NightRecord, modelContext: ModelContext) -> [NightEventRecord] {
    let sessionID = session.id
    let descriptor = FetchDescriptor<NightEventRecord>(
      predicate: #Predicate { $0.session?.id == sessionID }
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }

  /// Collects all audio file URLs of a night and clears its clips' names (the
  /// raw files are found by the night's id, so deleting them is enough).
  /// Returns the collected URLs so they can be deleted later off the main actor.
  @MainActor
  private func collectAndClearURLs(for session: NightRecord, modelContext: ModelContext) -> [URL] {
    var urls: [URL] = []

    let events = fetchEvents(for: session, modelContext: modelContext)
    for event in events {
      if let url = AudioFileURLResolver.resolve(event.clipFileName) {
        urls.append(url)
      }
      event.clipFileName = nil
    }

    for name in [session.rawAudioFileName, session.rawLogFileName] {
      if let url = AudioFileURLResolver.resolve(name) {
        urls.append(url)
      }
    }

    return urls
  }

  // MARK: - File deletion (background)

  /// Deletes the files in the plan and returns a report.
  private func deleteFiles(plan: CleanupPlan?) async -> CleanupReport {
    guard let plan, !plan.fileURLs.isEmpty else { return CleanupReport() }

    return await Task.detached {
      let fm = FileManager.default
      var bytes: Int64 = 0
      var files = 0

      for url in plan.fileURLs {
        let size = Self.fileSize(at: url, fm: fm)
        do {
          try fm.removeItem(at: url)
          bytes += size
          files += 1
        } catch {
          // File may already be gone; ignore.
        }
      }

      return CleanupReport(
        filesRemoved: files,
        bytesRemoved: bytes,
        sessionsAffected: plan.sessionsAffected)
    }.value
  }

  // MARK: - Size helpers

  private static func fileSize(at url: URL, fm: FileManager = .default) -> Int64 {
    guard let attrs = try? fm.attributesOfItem(atPath: url.path),
          let size = attrs[.size] as? Int64 else { return 0 }
    return size
  }

  // MARK: - Debug helpers

  #if DEBUG
  /// Creates dummy audio files and attaches them to existing sessions so the
  /// enforcer has something to clean up. Each file is ~1 MB.
  @MainActor
  public func injectDummyAudioForTesting(modelContext: ModelContext) -> Int {
    let descriptor = FetchDescriptor<NightRecord>(sortBy: [SortDescriptor(\.start)])
    guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else {
      Log.storage.notice("No sessions found — generate mock data first")
      return 0
    }

    let docs = AudioFileURLResolver.directory
    var created = 0
    let dummyData = Data(repeating: 0xAB, count: 1_024 * 1_024) // 1 MB

    for (index, session) in sessions.enumerated() {
      let filename = "test_event_\(index)_session_\(session.id.uuidString).m4a"
      let url = docs.appendingPathComponent(filename)
      try? dummyData.write(to: url)

      let event = NightEventRecord()
      event.start = session.start
      event.averageDB = -40
      event.peakDB = -30
      event.duration = 1.0
      event.clipFileName = filename
      modelContext.insert(event)
      event.session = session
      created += 1
    }

    try? modelContext.save()
    Log.storage.info("Created \(created) dummy audio file(s) (~1 MB each)")
    return created
  }
  #endif
}
