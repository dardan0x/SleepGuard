import Foundation
import Models
import ModelsTestSupport
import SleepCore
import SleepStore
import SwiftData
import Testing
@testable import Services

/// Storage cleanup deletes the oldest audio files (by age or total size) and
/// clears their references, but keeps every session and event.
/// Files are real, uniquely named, in the test host's clips folder. One test
/// at a time: a cleanup also removes files no night in its store names, which
/// would include another test's files.
@MainActor
@Suite(.serialized)
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

  /// Writes a file of `bytes` into the clips folder and returns its stored filename.
  /// Writes a file of `bytes` named `name` (a random one by default).
  private func audioFile(bytes: Int = 1_000, named name: String = "storage-test-\(UUID().uuidString).m4a") throws -> String {
    let url = AudioFileURLResolver.url(for: name)
    try Data(count: bytes).write(to: url)
    createdFiles.append(url)
    return name
  }

  private func exists(_ name: String) -> Bool {
    FileManager.default.fileExists(atPath: AudioFileURLResolver.url(for: name).path)
  }

  /// A session `daysAgo` old with one event clip of `eventBytes`.
  private func session(daysAgo: Double, eventBytes: Int = 1_000) throws -> (NightRecord, NightEventRecord) {
    let start = Date().addingTimeInterval(-daysAgo * 24 * 3600)
    let event = NightEventRecord.fixture(at: start)
    event.clipFileName = try audioFile(bytes: eventBytes)
    let session = try store.insert(.fixture(start: start), events: [event])
    return (session, event)
  }

  // MARK: - Day limit

  @Test func dayLimitRemovesEveryAudioFileOfOldSessionsOnly() async throws {
    let (old, oldEvent) = try session(daysAgo: 10)
    // The raw recording and its log, found by the night's id.
    let raw = try audioFile(named: RawRecording.audioFileName(for: old.id))
    let rawLog = try audioFile(named: RawRecording.logFileName(for: old.id))
    old.scoreVersion = "cached"
    old.score = 77
    let oldNames = try [#require(oldEvent.clipFileName), raw, rawLog]
    let (recent, recentEvent) = try session(daysAgo: 1)
    let recentName = try #require(recentEvent.clipFileName)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: 7, maxMB: nil)

    #expect(report.filesRemoved == 3)
    #expect(report.bytesRemoved == 3_000)
    #expect(report.sessionsAffected == 1)
    #expect(report.dayLimitSessions == 1)
    #expect(report.sizeLimitSessions == 0)
    #expect(oldNames.allSatisfy { !exists($0) })
    #expect(oldEvent.clipFileName == nil)
    #expect(old.rawAudioFileName == nil && old.rawLogFileName == nil)
    // Metadata stays.
    #expect(try store.context.fetchCount(FetchDescriptor<NightRecord>()) == 2)
    #expect(old.events.count == 1)
    #expect(old.score == 77)
    // Recent session untouched.
    #expect(exists(recentName))
    #expect(recentEvent.clipFileName == recentName)
    #expect(recent.events.count == 1)
  }

  // MARK: - Size limit

  @Test func sizeLimitRemovesOldestSessionsUntilUnderTheLimit() async throws {
    let (_, oldest) = try session(daysAgo: 3, eventBytes: Self.megabyte)
    let (_, middle) = try session(daysAgo: 2, eventBytes: Self.megabyte)
    let (_, newest) = try session(daysAgo: 1, eventBytes: Self.megabyte)
    let middleName = try #require(middle.clipFileName)
    let newestName = try #require(newest.clipFileName)

    // 3 MB total, 2 MB limit → only the oldest goes.
    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: 2)

    #expect(report.sizeLimitSessions == 1)
    #expect(report.bytesRemoved == Int64(Self.megabyte))
    #expect(oldest.clipFileName == nil)
    #expect(exists(middleName) && exists(newestName))
  }

  @Test func underTheSizeLimitNothingIsRemoved() async throws {
    let (_, event) = try session(daysAgo: 1, eventBytes: Self.megabyte)
    let name = try #require(event.clipFileName)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: 2)

    #expect(report.filesRemoved == 0)
    #expect(exists(name))
    #expect(event.clipFileName == name)
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
    let name = try #require(event.clipFileName)

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: nil, maxMB: nil)

    #expect(report.filesRemoved == 0)
    #expect(exists(name))
  }

  @Test func staleReferenceToAMissingFileIsClearedWithoutCounting() async throws {
    let start = Date().addingTimeInterval(-10 * 24 * 3600)
    let event = NightEventRecord.fixture(at: start)
    event.clipFileName = "missing-\(UUID().uuidString).m4a"
    _ = try store.insert(.fixture(start: start), events: [event])

    let report = await enforcer.enforceLimits(modelContext: store.context, maxDays: 7, maxMB: nil)

    #expect(event.clipFileName == nil)
    #expect(report.filesRemoved == 0)
    #expect(report.sessionsAffected == 0)
  }
}
