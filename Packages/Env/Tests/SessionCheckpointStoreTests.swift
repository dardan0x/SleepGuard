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

  @Test func loadAfterClearReturnsNil() async {
    store.write(snapshot(events: 1))
    await store.flush()
    store.clear()
    #expect(store.loadIfPresent() == nil)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
  }

  /// A saved night must never come back: a write still in flight when the
  /// night is cleared doesn't reach disk.
  @Test func aWriteInFlightNeverBringsBackAClearedFile() async {
    store.write(snapshot(events: 1))
    store.clear()
    await store.flush()
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
  }

  @Test func aWriteAfterClearIsKept() async throws {
    store.clear()
    let written = snapshot(events: 1)
    store.write(written)
    await store.flush()
    #expect(try #require(store.loadIfPresent()).id == written.id)
  }

  @Test func aBurstOfWritesCollapsesToTheLatest() async throws {
    let before = await store.diskWrites
    var latest = snapshot(events: 1)
    for count in 1...10 {
      latest = snapshot(events: count)
      store.write(latest)
    }
    await store.flush()
    let writes = await store.diskWrites - before
    #expect(writes < 10)
    #expect(try #require(store.loadIfPresent()).events.count == 10)
  }

  @Test func writtenSnapshotLoadsBack() async throws {
    let written = snapshot(events: 2)
    store.write(written)
    await store.flush()
    let loaded = try #require(store.loadIfPresent())
    #expect(loaded.id == written.id)
    #expect(loaded.lastCheckpointDate == written.lastCheckpointDate)
    #expect(loaded.events.map(\.id) == written.events.map(\.id))
  }

  @Test func laterWriteReplacesTheEarlierOne() async throws {
    store.write(snapshot(events: 1))
    let latest = snapshot(events: 3)
    store.write(latest)
    await store.flush()
    #expect(try #require(store.loadIfPresent()).id == latest.id)
  }

  @Test func snapshotWithoutEventsIsNotOffered() async {
    store.write(snapshot(events: 0))
    await store.flush()
    #expect(FileManager.default.fileExists(atPath: fileURL.path))
    #expect(store.loadIfPresent() == nil)
  }

  @Test func corruptFileIsIgnored() throws {
    try Data("not json".utf8).write(to: fileURL)
    #expect(store.loadIfPresent() == nil)
  }
}
