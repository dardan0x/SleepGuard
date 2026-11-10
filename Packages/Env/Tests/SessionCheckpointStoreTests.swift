import Foundation
import Models
import ModelsTestSupport
import Testing
@testable import Env

/// Crash-recovery file (`Documents/session_recovery.json`). One shared file,
/// so the suite runs serially and clears it before and after each test.
@MainActor
@Suite(.serialized)
final class SessionCheckpointStoreTests {
  private let store = SessionCheckpointStore.shared
  private let start = TestCalendar.date(day: 1, hour: 23)
  private let fileURL = AudioFileURLResolver.url(for: "session_recovery.json")

  init() {
    store.clear()
  }

  deinit {
    try? FileManager.default.removeItem(at: AudioFileURLResolver.url(for: "session_recovery.json"))
  }

  private func snapshot(events: Int) -> SessionRecoverySnapshot {
    let session = SleepSession(startDate: start)
    session.events = (0..<events).map { .fixture(at: start.addingTimeInterval(Double($0) * 600)) }
    return SessionRecoverySnapshot(from: session, checkpointDate: start.addingTimeInterval(3600))
  }

  @Test func loadAfterClearReturnsNil() {
    store.write(snapshot(events: 1))
    store.clear()
    #expect(store.loadIfPresent() == nil)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
  }

  @Test func writtenSnapshotLoadsBack() throws {
    let written = snapshot(events: 2)
    store.write(written)
    let loaded = try #require(store.loadIfPresent())
    #expect(loaded.id == written.id)
    #expect(loaded.lastCheckpointDate == written.lastCheckpointDate)
    #expect(loaded.events.map(\.id) == written.events.map(\.id))
  }

  @Test func laterWriteReplacesTheEarlierOne() throws {
    store.write(snapshot(events: 1))
    let latest = snapshot(events: 3)
    store.write(latest)
    #expect(try #require(store.loadIfPresent()).id == latest.id)
  }

  @Test func snapshotWithoutEventsIsNotOffered() {
    store.write(snapshot(events: 0))
    #expect(FileManager.default.fileExists(atPath: fileURL.path))
    #expect(store.loadIfPresent() == nil)
  }

  @Test func corruptFileIsIgnored() throws {
    try Data("not json".utf8).write(to: fileURL)
    #expect(store.loadIfPresent() == nil)
  }
}
