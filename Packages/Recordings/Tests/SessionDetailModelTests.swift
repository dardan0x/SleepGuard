import Config
import ConfigTestSupport
import FactoryKit
import FactoryTesting
import Foundation
import HealthTestSupport
import Models
import ModelsTestSupport
import SleepCore
import SwiftData
import Testing
@testable import Recordings

/// Session detail state owner: read-only load, enrichment (stages, stale
/// score), event filters, and delete.
/// Each test gets isolated `AppConfig` / `UserPreferences` (default flags all
/// on, `enhancedSleepTracking` off) and its own Factory scope (`.container`),
/// so HealthKit fakes and settings never leak between parallel tests.
@Suite(.container)
final class SessionDetailModelTests {
  private let store: TestStore
  private let appConfig = AppConfig.isolated()
  private let preferences = UserPreferences.isolated()
  private let start = TestCalendar.date(day: 1, hour: 23)
  private var createdFiles: [URL] = []

  init() throws {
    store = try TestStore()
  }

  deinit {
    for url in createdFiles {
      try? FileManager.default.removeItem(at: url)
    }
  }

  private func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  private func model(for session: SleepSession) -> SessionDetailModel {
    SessionDetailModel(sessionID: session.id, appConfig: appConfig, userPreferences: preferences)
  }

  private func clipFile() throws -> String {
    let name = "detail-test-\(UUID().uuidString).m4a"
    let url = AudioFileURLResolver.url(for: name)
    try Data([1]).write(to: url)
    createdFiles.append(url)
    return name
  }

  /// One merged snoring episode (2 events), one micro-episode, sleep talking, noise.
  private func night() throws -> (SleepSession, [String: SnoreEvent]) {
    let events: [String: SnoreEvent] = [
      "snoreA": .fixture(at: at(0), duration: 30),
      "snoreB": .fixture(at: at(60), duration: 120),
      "micro": .fixture(at: at(3600), duration: 2),
      "talk": .fixture(at: at(7200), duration: 20, category: .sleepTalking),
      "noise": .fixture(at: at(9000), duration: 10, category: .noise),
    ]
    let session = try store.insert(.fixture(start: start), events: Array(events.values))
    return (session, events)
  }

  // MARK: - Load

  @MainActor
  @Test func loadReadsWithoutWriting() throws {
    let (session, _) = try night()
    session.hasCachedScore = true
    session.cachedSleepScore = 1 // stale
    try store.context.save()
    let model = model(for: session)

    model.load(modelContext: store.context)

    guard case let .loaded(loaded, sortedEvents, isClipSession) = model.viewState else {
      Issue.record("expected .loaded")
      return
    }
    #expect(loaded.id == session.id)
    #expect(sortedEvents.map(\.timestamp) == sortedEvents.map(\.timestamp).sorted())
    #expect(!isClipSession)
    #expect(session.cachedSleepScore == 1)
    #expect(!store.context.hasChanges)
  }

  @MainActor
  @Test func enrichRefreshesAStaleCachedScore() async throws {
    let (session, _) = try night()
    session.hasCachedScore = true
    session.cachedSleepScore = 1 // stale: no version stamp
    let model = model(for: session)

    model.load(modelContext: store.context)
    await model.enrichIfNeeded(modelContext: store.context)

    #expect(session.hasCachedScore)
    #expect(session.cachedSleepScore == session.sleepScore(using: appConfig.sleepScoreConfig))
    #expect(!store.context.hasChanges)
  }

  @MainActor
  @Test func enrichLeavesACurrentCachedScoreAlone() async throws {
    let (session, _) = try night()
    session.refreshCachedScore(using: appConfig.sleepScoreConfig)
    session.cachedSleepScore = 1 // stamped current, so not recomputed
    try store.context.save()
    let model = model(for: session)

    model.load(modelContext: store.context)
    await model.enrichIfNeeded(modelContext: store.context)

    #expect(session.cachedSleepScore == 1)
  }

  @MainActor
  @Test func loadingAnUnknownSessionIsAnError() async {
    let model = SessionDetailModel(sessionID: UUID(), appConfig: appConfig, userPreferences: preferences)
    model.load(modelContext: store.context)
    guard case .error = model.viewState else {
      Issue.record("expected .error")
      return
    }
  }

  @MainActor
  @Test func sessionWithAnExistingClipIsAClipSession() async throws {
    let event = SnoreEvent.fixture(at: at(0))
    event.audioFileURL = try clipFile()
    let session = try store.insert(.fixture(start: start), events: [event])
    let model = model(for: session)
    model.load(modelContext: store.context)
    guard case let .loaded(_, _, isClipSession) = model.viewState else {
      Issue.record("expected .loaded")
      return
    }
    #expect(isClipSession)
  }

  // MARK: - HealthKit

  @MainActor
  @Test func loadFetchesStagesAndScoresThem() async throws {
    // Deep 0%, REM 0% → stage penalty (15 × 0.6 + 18 × 0.4 = 16.2) capped at 15.
    let fake = FakeHealthKitSync(
      isAuthorized: true,
      stages: [SleepStageSegment(stage: .light, startOffset: 0, duration: 8 * 3600)])
    Container.shared.healthKitSync.register { fake }
    let session = try store.insert(.fixture(start: start))

    preferences.enhancedSleepTracking = true

    let model = model(for: session)
    model.load(modelContext: store.context)
    await model.enrichIfNeeded(modelContext: store.context)

    #expect(fake.fetchedSessionIDs == [session.id])
    #expect(session.sleepStageSegments?.count == 1)
    #expect(session.cachedSleepScore == 85)
  }

  @MainActor
  @Test func loadSkipsHealthKitWhenTrackingIsOff() async throws {
    let fake = FakeHealthKitSync(isAuthorized: true)
    Container.shared.healthKitSync.register { fake }
    let session = try store.insert(.fixture(start: start))

    let model = model(for: session)
    model.load(modelContext: store.context)
    await model.enrichIfNeeded(modelContext: store.context)

    #expect(fake.fetchedSessionIDs.isEmpty)
    #expect(session.sleepStageSegments == nil)
  }

  // MARK: - Filters

  @MainActor
  @Test func filtersShowEpisodeRepresentativesAndOtherEvents() async throws {
    let (session, e) = try night()
    let model = model(for: session)
    model.load(modelContext: store.context)
    let ids = { model.rows.map(\.id) }

    model.selectedFilter = .all
    #expect(try ids() == [#require(e["snoreB"]).id, #require(e["talk"]).id, #require(e["noise"]).id])
    model.selectedFilter = .snoring
    #expect(try ids() == [#require(e["snoreB"]).id]) // representative = longest; micro hidden
    model.selectedFilter = .sleepTalking
    #expect(try ids() == [#require(e["talk"]).id])
    model.selectedFilter = .noise
    #expect(try ids() == [#require(e["noise"]).id])
  }

  @MainActor
  @Test func shortEventsRowsAndFilters() async throws {
    let (session, e) = try night()
    let model = model(for: session)
    model.load(modelContext: store.context)

    #expect(try model.shortEvents.map(\.id) == [#require(e["micro"]).id])
    let snoringRow = try #require(model.rows.first { $0.category == .snoring })
    #expect(try snoringRow.id == #require(e["snoreB"]).id)
    #expect(snoringRow.duration == 150) // 30 + 120
    #expect(model.filters == EventFilter.allCases)
    #expect(try model.event(for: snoringRow)?.id == #require(e["snoreB"]).id)
  }

  @MainActor
  @Test func singleCategoryHidesTheFilter() async throws {
    let session = try store.insert(.fixture(start: start), events: [.fixture(at: at(0), duration: 30)])
    let model = model(for: session)
    model.load(modelContext: store.context)
    #expect(model.filters.isEmpty)
  }

  // MARK: - Delete

  @MainActor
  @Test func deleteRemovesTheSessionEventsAndAllAudioFiles() async throws {
    let event = SnoreEvent.fixture(at: at(0))
    let clip = try clipFile()
    event.audioFileURL = clip
    let session = try store.insert(.fixture(start: start), events: [event])
    let raw = try clipFile()
    session.rawAudioFileURL = raw
    try store.context.save()

    #expect(model(for: session).delete(modelContext: store.context))

    #expect(try store.context.fetchCount(FetchDescriptor<SleepSession>()) == 0)
    #expect(try store.context.fetchCount(FetchDescriptor<SnoreEvent>()) == 0)
    #expect(!FileManager.default.fileExists(atPath: AudioFileURLResolver.url(for: raw).path))
    #expect(!FileManager.default.fileExists(atPath: AudioFileURLResolver.url(for: clip).path))
  }

  @MainActor
  @Test func deletingAnAlreadyDeletedSessionCountsAsDone() {
    let model = SessionDetailModel(sessionID: UUID(), appConfig: appConfig, userPreferences: preferences)
    #expect(model.delete(modelContext: store.context))
  }
}
