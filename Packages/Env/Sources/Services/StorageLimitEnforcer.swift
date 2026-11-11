import FactoryKit
import Foundation
import Models
import SwiftData

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
    let prefs = Container.shared.userPreferences()
    return await enforceLimits(
      modelContext: modelContext,
      maxDays: prefs.limitDaysEnabled ? prefs.maxDays : nil,
      maxMB: prefs.limitStorageEnabled ? prefs.storageLimitMB : nil)
  }

  /// Same as above with explicit limits (`nil` = that limit is off), so tests
  /// don't depend on `UserDefaults`.
  @MainActor
  @discardableResult
  func enforceLimits(modelContext: ModelContext, maxDays: Int?, maxMB: Int?) async -> CleanupReport {
    var dayPlan: CleanupPlan?
    var sizePlan: CleanupPlan?

    if let maxDays {
      dayPlan = buildDayPlan(maxDays: maxDays, modelContext: modelContext)
    }
    if let maxMB {
      sizePlan = buildSizePlan(maxMB: maxMB, modelContext: modelContext)
    }

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

    let report = CleanupReport(
      filesRemoved: dayReport.filesRemoved + sizeReport.filesRemoved,
      bytesRemoved: dayReport.bytesRemoved + sizeReport.bytesRemoved,
      sessionsAffected: dayReport.sessionsAffected + sizeReport.sessionsAffected,
      dayLimitSessions: dayReport.sessionsAffected,
      sizeLimitSessions: sizeReport.sessionsAffected)

    Log.storage.info("Cleanup complete — \(report.filesRemoved) file(s), \(report.bytesRemoved / 1_024 / 1_024) MB, \(report.sessionsAffected) session(s)")
    return report
  }

  // MARK: - Plan builders (MainActor)

  /// Builds a plan of files to delete for sessions older than `maxDays`.
  /// Also clears the audio URL properties on the model objects.
  @MainActor
  private func buildDayPlan(maxDays: Int, modelContext: ModelContext) -> CleanupPlan {
    let cutoff = Date().addingTimeInterval(-TimeInterval(maxDays) * 24 * 3600)
    let descriptor = FetchDescriptor<SleepSession>(
      predicate: #Predicate { $0.startDate < cutoff }
    )

    guard let sessions = try? modelContext.fetch(descriptor) else {
      return CleanupPlan(fileURLs: [], sessionsAffected: 0)
    }

    var urls: [URL] = []
    var affected = 0
    for session in sessions {
      let sessionURLs = collectAndClearURLs(for: session, modelContext: modelContext)
      if !sessionURLs.isEmpty {
        urls.append(contentsOf: sessionURLs)
        affected += 1
      }
    }

    if affected > 0 {
      Log.storage.info("Planned removal for \(affected) sessions older than \(maxDays) days")
    }
    return CleanupPlan(fileURLs: urls, sessionsAffected: affected)
  }

  /// Builds a plan of files to delete to get under `maxMB`.
  /// Also clears the audio URL properties on the model objects.
  @MainActor
  private func buildSizePlan(maxMB: Int, modelContext: ModelContext) -> CleanupPlan {
    let maxBytes = Int64(maxMB) * 1_024 * 1_024
    let descriptor = FetchDescriptor<SleepSession>(sortBy: [SortDescriptor(\.startDate)])

    guard let sessions = try? modelContext.fetch(descriptor) else {
      return CleanupPlan(fileURLs: [], sessionsAffected: 0)
    }

    var totalSize = totalAudioSize(for: sessions, modelContext: modelContext)
    guard totalSize > maxBytes else {
      return CleanupPlan(fileURLs: [], sessionsAffected: 0)
    }

    var urls: [URL] = []
    var affected = 0
    for session in sessions {
      if totalSize <= maxBytes { break }
      let sessionSize = audioSize(for: session, modelContext: modelContext)
      let sessionURLs = collectAndClearURLs(for: session, modelContext: modelContext)
      if !sessionURLs.isEmpty {
        urls.append(contentsOf: sessionURLs)
        affected += 1
      }
      totalSize -= sessionSize
    }

    if affected > 0 {
      Log.storage.info("Planned removal to get under \(maxMB) MB")
    }
    return CleanupPlan(fileURLs: urls, sessionsAffected: affected)
  }

  // MARK: - Event fetching (avoids faulting corrupted relationships)

  @MainActor
  private func fetchEvents(for session: SleepSession, modelContext: ModelContext) -> [SnoreEvent] {
    let sessionID = session.id
    let descriptor = FetchDescriptor<SnoreEvent>(
      predicate: #Predicate { $0.session?.id == sessionID }
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }

  /// Collects all audio file URLs for a session/events and clears the model properties.
  /// Returns the collected URLs so they can be deleted later off the main actor.
  @MainActor
  private func collectAndClearURLs(for session: SleepSession, modelContext: ModelContext) -> [URL] {
    var urls: [URL] = []

    let events = fetchEvents(for: session, modelContext: modelContext)
    for event in events {
      if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
        urls.append(url)
      }
      event.audioFileURL = nil
    }

    if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
      urls.append(url)
    }
    session.audioFileURL = nil

    if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
      urls.append(url)
    }
    session.rawAudioFileURL = nil

    if let url = AudioFileURLResolver.resolve(session.rawLogFileURL) {
      urls.append(url)
    }
    session.rawLogFileURL = nil

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

  @MainActor
  private func totalAudioSize(for sessions: [SleepSession], modelContext: ModelContext) -> Int64 {
    var total: Int64 = 0
    for session in sessions {
      total += audioSize(for: session, modelContext: modelContext)
    }
    return total
  }

  @MainActor
  private func audioSize(for session: SleepSession, modelContext: ModelContext) -> Int64 {
    var size: Int64 = 0

    let events = fetchEvents(for: session, modelContext: modelContext)
    for event in events {
      if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
        size += fileSize(at: url)
      }
    }

    if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
      size += fileSize(at: url)
    }
    if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
      size += fileSize(at: url)
    }
    if let url = AudioFileURLResolver.resolve(session.rawLogFileURL) {
      size += fileSize(at: url)
    }

    return size
  }

  private static func fileSize(at url: URL, fm: FileManager = .default) -> Int64 {
    guard let attrs = try? fm.attributesOfItem(atPath: url.path),
          let size = attrs[.size] as? Int64 else { return 0 }
    return size
  }

  private func fileSize(at url: URL) -> Int64 {
    Self.fileSize(at: url, fm: FileManager.default)
  }

  // MARK: - Debug helpers

  #if DEBUG
  /// Creates dummy audio files and attaches them to existing sessions so the
  /// enforcer has something to clean up. Each file is ~1 MB.
  @MainActor
  public func injectDummyAudioForTesting(modelContext: ModelContext) -> Int {
    let descriptor = FetchDescriptor<SleepSession>(sortBy: [SortDescriptor(\.startDate)])
    guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else {
      Log.storage.notice("No sessions found — generate mock data first")
      return 0
    }

    let docs = AudioFileURLResolver.documentsDirectory
    var created = 0
    let dummyData = Data(repeating: 0xAB, count: 1_024 * 1_024) // 1 MB

    for (index, session) in sessions.enumerated() {
      let filename = "test_event_\(index)_session_\(session.id.uuidString).m4a"
      let url = docs.appendingPathComponent(filename)
      try? dummyData.write(to: url)

      let event = SnoreEvent(
        timestamp: session.startDate,
        category: .snoring,
        intensity: .quiet,
        averageDB: -40,
        peakDB: -30,
        duration: 1.0)
      event.audioFileURL = filename
      event.session = session
      if session.events == nil { session.events = [] }
      session.events?.append(event)
      modelContext.insert(event)
      created += 1
    }

    try? modelContext.save()
    Log.storage.info("Created \(created) dummy audio file(s) (~1 MB each)")
    return created
  }
  #endif
}
