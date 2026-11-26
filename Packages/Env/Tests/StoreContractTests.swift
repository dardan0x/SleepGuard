import ConfigTestSupport
import EnvTestSupport
import Foundation
import Models
import ModelsTestSupport
import SleepCore
import Testing
@testable import Env

/// The same behaviour checked against each real store and its fake, so a test
/// that uses the fake can trust it (principal review Q24/Q59: fakes drift).
///
/// Only stores whose state is visible through their own protocol have a
/// contract. The others are effect-only by design: `FakePendingSessionStore`,
/// `FakeStorageLimitEnforcer` and `FakeSessionRawLogWriter` record calls or skip
/// work, and their real types are covered by their own tests.
@MainActor
struct StoreContractTests {
  private let start = TestCalendar.date(day: 1, hour: 23)

  // MARK: - SessionCheckpointStoring

  private func snapshot(events: Int) -> SessionRecoverySnapshot {
    let session = SleepSession(startDate: start)
    session.events = (0..<events).map { .fixture(at: start.addingTimeInterval(Double($0) * 600)) }
    return SessionRecoverySnapshot(from: session, checkpointDate: start.addingTimeInterval(3600))
  }

  /// `settle` waits for writes that leave the caller (the real store's writer).
  private func checkpointContract(_ store: any SessionCheckpointStoring, settle: () async -> Void) async {
    store.clear()
    #expect(store.loadIfPresent() == nil)

    let first = snapshot(events: 2)
    store.write(first)
    await settle()
    #expect(store.loadIfPresent()?.id == first.id)

    let latest = snapshot(events: 3)
    store.write(latest)
    await settle()
    #expect(store.loadIfPresent()?.id == latest.id)
    #expect(store.loadIfPresent()?.events.count == 3)

    // A night with nothing to recover isn't offered.
    store.write(snapshot(events: 0))
    await settle()
    #expect(store.loadIfPresent() == nil)

    store.write(first)
    store.clear()
    await settle()
    #expect(store.loadIfPresent() == nil)
  }

  @Test func realCheckpointStoreMeetsTheContract() async {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("recovery-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    let store = SessionCheckpointStore(url: url)
    await checkpointContract(store) { await store.flush() }
  }

  @Test func fakeCheckpointStoreMeetsTheContract() async {
    await checkpointContract(FakeSessionCheckpointStore()) {}
  }

  // MARK: - CustomMelodyStoring

  private func recording() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("contract-\(UUID().uuidString).m4a")
    try Data([1, 2, 3]).write(to: url)
    return url
  }

  private func melodyContract(_ storage: any CustomMelodyStoring) throws {
    #expect(storage.customMelodies.isEmpty)

    let first = try #require(storage.saveRecording(name: "Mine", from: recording()))
    let second = try #require(storage.saveRecording(name: "Also mine", from: recording()))
    #expect(first.isCustom && second.isCustom)
    #expect(first.id != second.id)
    #expect(storage.allCustomMelodies().map(\.id) == [first.id, second.id])
    #expect(storage.melody(id: first.id)?.customName == "Mine")
    #expect(storage.melody(filename: second.filename)?.id == second.id)
    #expect(storage.resolve(id: second.id).id == second.id)

    storage.deleteMelody(id: first.id)
    #expect(storage.customMelodies.map(\.id) == [second.id])
    #expect(storage.melody(id: first.id) == nil)

    storage.deleteMelody(id: 999_999) // unknown: nothing happens
    #expect(storage.customMelodies.count == 1)
  }

  @Test func realMelodyStorageMeetsTheContract() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("melodies-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try melodyContract(CustomMelodyStorage(defaults: .isolated(), directory: directory))
  }

  @Test func fakeMelodyStorageMeetsTheContract() throws {
    try melodyContract(FakeCustomMelodyStorage())
  }
}
