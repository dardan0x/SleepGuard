import Foundation
import ModelsTestSupport
import Testing
@testable import Models

/// Episode grouping (`snoringEpisodes`, 5-minute merge gap), the < 3 s display
/// filter, playback lookup, and `SnoringEpisode` aggregates.
@MainActor
struct SnoringEpisodeTests {
  private let store: TestStore
  private let start = TestCalendar.date(day: 1, hour: 23)

  init() throws {
    store = try TestStore()
  }

  private func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  private func night(_ events: [SnoreEvent]) throws -> SleepSession {
    try store.insert(.fixture(start: start), events: events)
  }

  // MARK: - Grouping

  @Test func noSnoringEventsMeansNoEpisodes() throws {
    let talking = SnoreEvent.fixture(at: at(0), category: .sleepTalking)
    #expect(try night([]).snoringEpisodes.isEmpty)
    #expect(try night([talking]).snoringEpisodes.isEmpty)
  }

  @Test func eventsExactlyFiveMinutesApartMerge() throws {
    // e1 ends at 60 s; e2 starts at 360 s → gap 300 s (≤ 300 merges)
    let e1 = SnoreEvent.fixture(at: at(0), duration: 60, intensity: .light)
    let e2 = SnoreEvent.fixture(at: at(360), duration: 60, intensity: .epic)
    let episodes = try night([e1, e2]).snoringEpisodes
    #expect(episodes.count == 1)
    #expect(episodes[0].duration == 420)
    #expect(episodes[0].intensity == .epic)
    #expect(episodes[0].id == e1.id)
  }

  @Test func eventsMoreThanFiveMinutesApartSplit() throws {
    let e1 = SnoreEvent.fixture(at: at(0), duration: 60)
    let e2 = SnoreEvent.fixture(at: at(361), duration: 60)
    let episodes = try night([e1, e2]).snoringEpisodes
    #expect(episodes.map(\.id) == [e1.id, e2.id])
    #expect(episodes.map(\.duration) == [60, 60])
  }

  @Test func eventsAreOrderedByTimeBeforeGrouping() throws {
    let late = SnoreEvent.fixture(at: at(3600), duration: 60)
    let early = SnoreEvent.fixture(at: at(0), duration: 60)
    let episodes = try night([late, early]).snoringEpisodes
    #expect(episodes.map(\.startTime) == [at(0), at(3600)])
  }

  @Test func eventInsideAnotherDoesNotShortenTheEpisode() throws {
    let long = SnoreEvent.fixture(at: at(0), duration: 600)
    let inside = SnoreEvent.fixture(at: at(100), duration: 60)
    let episodes = try night([long, inside]).snoringEpisodes
    #expect(episodes.count == 1)
    #expect(episodes[0].duration == 600)
  }

  @Test func sleepTalkingDoesNotJoinSnoringEpisodes() throws {
    let snore = SnoreEvent.fixture(at: at(0), duration: 60)
    let talking = SnoreEvent.fixture(at: at(30), duration: 60, category: .sleepTalking)
    let episodes = try night([snore, talking]).snoringEpisodes
    #expect(episodes.count == 1)
    #expect(episodes[0].events.map(\.id) == [snore.id])
  }

  // MARK: - Display filter + counts

  @Test func episodesUnderThreeSecondsAreHidden() throws {
    let tooShort = SnoreEvent.fixture(at: at(0), duration: 2.9)
    let justEnough = SnoreEvent.fixture(at: at(3600), duration: 3)
    let session = try night([tooShort, justEnough])
    #expect(session.snoringEpisodes.count == 2)
    #expect(session.displayableSnoringEpisodes.map(\.id) == [justEnough.id])
  }

  @Test func eventsCountIsDisplayableEpisodesPlusOtherEvents() throws {
    let session = try night([
      .fixture(at: at(0), duration: 60),
      .fixture(at: at(120), duration: 60), // merges with the first
      .fixture(at: at(3600), duration: 1), // hidden micro-episode
      .fixture(at: at(7200), duration: 30, category: .sleepTalking),
    ])
    #expect(session.eventsCount == 2)
    #expect(session.eventsPerHour == 0.25) // 2 / 8 h
  }

  @Test func eventsPerHourIsZeroForUnfinishedSession() throws {
    let session = try store.insert(
      SleepSession(startDate: start),
      events: [.fixture(at: at(0), duration: 60)])
    #expect(session.eventsPerHour == 0)
  }

  // MARK: - Playback lookup

  @Test func representativeEventPlaysTheWholeEpisodeInOrder() throws {
    let first = SnoreEvent.fixture(at: at(0), duration: 30)
    let longest = SnoreEvent.fixture(at: at(100), duration: 120)
    let session = try night([longest, first])
    let episode = try #require(session.displayableSnoringEpisodes.first)
    #expect(episode.representativeEvent?.id == longest.id)
    #expect(session.episodePlaybackEvents(for: longest).map(\.id) == [first.id, longest.id])
  }

  @Test func nonRepresentativeAndNonSnoringEventsPlayAlone() throws {
    let first = SnoreEvent.fixture(at: at(0), duration: 30)
    let longest = SnoreEvent.fixture(at: at(100), duration: 120)
    let talking = SnoreEvent.fixture(at: at(7200), duration: 30, category: .sleepTalking)
    let session = try night([first, longest, talking])
    #expect(session.episodePlaybackEvents(for: first).map(\.id) == [first.id])
    #expect(session.episodePlaybackEvents(for: talking).map(\.id) == [talking.id])
  }

  // MARK: - Episode aggregates

  @Test func detectedDurationUsesBurstsWhenPresent() throws {
    let withBursts = SnoreEvent.fixture(
      at: at(0), duration: 600,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 20), SnoreBurst(startOffset: 100, endOffset: 130)])
    let legacy = SnoreEvent.fixture(at: at(700), duration: 40)
    let episode = try #require(night([withBursts, legacy]).snoringEpisodes.first)
    #expect(episode.snoreDuration == 640)
    #expect(episode.detectedDuration == 90) // 20 + 30 + 40
  }

  @Test func detectedSegmentsFollowBurstsSortedByStart() throws {
    let event = SnoreEvent.fixture(
      at: at(0), duration: 600, intensity: .loud,
      bursts: [SnoreBurst(startOffset: 300, endOffset: 310), SnoreBurst(startOffset: 0, endOffset: 20)])
    let episode = try #require(night([event]).snoringEpisodes.first)
    let segments = episode.detectedSegments
    #expect(segments.map(\.start) == [at(0), at(300)])
    #expect(segments.map(\.duration) == [20, 10])
    #expect(segments.allSatisfy { $0.intensity == .loud })
  }

  @Test func detectedSegmentsFallBackToWholeEventsWithoutBursts() throws {
    let e1 = SnoreEvent.fixture(at: at(0), duration: 60)
    let e2 = SnoreEvent.fixture(at: at(120), duration: 30)
    let episode = try #require(night([e1, e2]).snoringEpisodes.first)
    #expect(episode.detectedSegments.map(\.start) == [at(0), at(120)])
    #expect(episode.detectedSegments.map(\.duration) == [60, 30])
  }

  @Test func peakIsMaxAndAverageIsDurationWeighted() throws {
    let quiet = SnoreEvent.fixture(at: at(0), duration: 60, averageDB: -40, peakDB: -30)
    let loud = SnoreEvent.fixture(at: at(100), duration: 180, averageDB: -20, peakDB: -10)
    let episode = try #require(night([quiet, loud]).snoringEpisodes.first)
    #expect(episode.peakDB == -10)
    #expect(episode.averageDB == -25) // (−40 × 60 + −20 × 180) / 240
  }

  @Test func eventDurationFallsBackToBurstSum() {
    let event = SnoreEvent.fixture(
      at: at(0), duration: 0,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 5), SnoreBurst(startOffset: 10, endOffset: 12)])
    #expect(event.snoreDuration == 7)
  }
}
