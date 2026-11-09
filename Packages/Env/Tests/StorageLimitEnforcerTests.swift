import Foundation
import Models
import ModelsTestSupport
import SwiftData
import Testing
@testable import Env

/// Storage cleanup deletes the oldest audio files (by age or total size) and
/// clears their references, but keeps every session and event.
/// Files are real, uniquely named, in the test host's Documents folder.
@MainActor
final class StorageLimitEnforcerTests {
  private let store: TestStore
  private let enforcer = StorageLimitEnforcer.shared
  private var createdFiles: [URL] = []
  private static let megabyte = 1_024 * 1_024

  init() throws {
    store = try TestStore()
  }

  deinit {
    for url in createdFiles {
      try? FileManager.default.removeItem(at: url)
    }
  }

  /// Writes a file of `bytes` into Documents and returns its stored filename.
  private func audioFile(bytes: Int = 1_000) throws -> String {
    let name = "storage-test-\(UUID().uuidString).m4a"
    let url = AudioFileURLResolver.url(for: name)
    try Data(count: bytes).write(to: url)
    createdFiles.append(url)
    return name
  }

  private func exists(_ name: String) -> Bool {
    FileManager.default.fileExists(atPath: AudioFileURLResolver.url(for: name).path)
  }

  /// A session `daysAgo` old with one event clip of `eventBytes`.
  private func session(daysAgo: Double, eventBytes: Int = 1_000) throws -> (SleepSession, SnoreEvent) {
    let start = Date().addingTimeInterval(-daysAgo * 24 * 3600)
    let event = SnoreEvent.fixture(at: start)
    event.audioFileURL = try audioFile(bytes: eventBytes)
    let session = try store.insert(.fixture(start: start), events: [event])
    return (session, event)
  }

  // MARK: - Day limit

  @Test func dayLimitRemovesEveryAudioFileOfOldSessionsOnly() async throws {
    let (old, oldEvent) = try session(daysAgo: 10)
    old.audioFileURL = try audioFile()
    old.rawAudioFileURL = try audioFile()
    old.rawLogFileURL = try audioFile()
    old.hasCachedScore = true
    old.cachedSleepScore = 77
    let oldNames = try [oldEvent.audioFileURL, old.audioFileURL, old.rawAudioFileURL, old.rawLogFileURL].map { try #require($0) }
    let (recent, recentEvent) = try session(daysAgo: 1)
    let recentName = try #require(recentEvent.audioFileURL)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: 7, maxMB: nil)

    #expect(report.filesRemoved == 4)
    #expect(report.bytesRemoved == 4_000)
    #expect(report.sessionsAffected == 1)
    #expect(report.dayLimitSessions == 1)
    #expect(report.sizeLimitSessions == 0)
    #expect(oldNames.allSatisfy { !exists($0) })
    #expect(oldEvent.audioFileURL == nil)
    #expect(old.audioFileURL == nil && old.rawAudioFileURL == nil && old.rawLogFileURL == nil)
    // Metadata stays.
    #expect(try store.context.fetchCount(FetchDescriptor<SleepSession>()) == 2)
    #expect(old.events?.count == 1)
    #expect(old.sleepScore == 77)
    // Recent session untouched.
    #expect(exists(recentName))
    #expect(recentEvent.audioFileURL == recentName)
    #expect(recent.events?.count == 1)
  }

  // MARK: - Size limit

  @Test func sizeLimitRemovesOldestSessionsUntilUnderTheLimit() async throws {
    let (_, oldest) = try session(daysAgo: 3, eventBytes: Self.megabyte)
    let (_, middle) = try session(daysAgo: 2, eventBytes: Self.megabyte)
    let (_, newest) = try session(daysAgo: 1, eventBytes: Self.megabyte)
    let middleName = try #require(middle.audioFileURL)
    let newestName = try #require(newest.audioFileURL)

    // 3 MB total, 2 MB limit → only the oldest goes.
    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: 2)

    #expect(report.sizeLimitSessions == 1)
    #expect(report.bytesRemoved == Int64(Self.megabyte))
    #expect(oldest.audioFileURL == nil)
    #expect(exists(middleName) && exists(newestName))
  }

  @Test func underTheSizeLimitNothingIsRemoved() async throws {
    let (_, event) = try session(daysAgo: 1, eventBytes: Self.megabyte)
    let name = try #require(event.audioFileURL)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: 2)

    #expect(report.filesRemoved == 0)
    #expect(exists(name))
    #expect(event.audioFileURL == name)
  }

  // MARK: - Combined + edge cases

  @Test func filesRemovedByTheDayLimitAreNotCountedAgainByTheSizeLimit() async throws {
    _ = try session(daysAgo: 10, eventBytes: Self.megabyte)
    _ = try session(daysAgo: 2, eventBytes: Self.megabyte)
    _ = try session(daysAgo: 1, eventBytes: Self.megabyte)

    // Day limit takes the old one; the remaining 2 MB is within the 2 MB limit.
    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: 7, maxMB: 2)

    #expect(report.dayLimitSessions == 1)
    #expect(report.sizeLimitSessions == 0)
    #expect(report.filesRemoved == 1)
  }

  @Test func noLimitsMeansNoChanges() async throws {
    let (_, event) = try session(daysAgo: 400)
    let name = try #require(event.audioFileURL)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: nil)

    #expect(report.filesRemoved == 0)
    #expect(exists(name))
  }

  @Test func staleReferenceToAMissingFileIsClearedWithoutCounting() async throws {
    let start = Date().addingTimeInterval(-10 * 24 * 3600)
    let event = SnoreEvent.fixture(at: start)
    event.audioFileURL = "missing-\(UUID().uuidString).m4a"
    _ = try store.insert(.fixture(start: start), events: [event])

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: 7, maxMB: nil)

    #expect(event.audioFileURL == nil)
    #expect(report.filesRemoved == 0)
    #expect(report.sessionsAffected == 0)
  }
}
