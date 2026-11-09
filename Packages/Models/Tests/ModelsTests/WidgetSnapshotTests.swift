import Foundation
import Testing
@testable import Models

struct WidgetSnapshotBuilderTests {
  private let calendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
  }()

  private func date(day: Int, hour: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
  }

  private func session(
    day: Int,
    hour: Int = 23,
    hours: Double = 7,
    score: Int = 80,
    snoring: TimeInterval = 600,
    cached: Bool = true,
    ended: Bool = true) -> SleepSession
  {
    let start = date(day: day, hour: hour)
    let session = SleepSession(startDate: start, endDate: ended ? start.addingTimeInterval(hours * 3600) : nil)
    session.hasCachedScore = cached
    session.cachedSleepScore = score
    session.cachedSnoringDuration = snoring
    return session
  }

  @Test func emptyInputProducesEmptySnapshot() {
    let snapshot = WidgetSnapshotBuilder.make(from: [], calendar: calendar)
    #expect(snapshot.lastNight == nil)
    #expect(snapshot.recentDays.isEmpty)
  }

  @Test func lastNightIsMostRecentByStartDate() {
    let older = session(day: 1, score: 60)
    let newest = session(day: 3, score: 90, snoring: 1200)
    let middle = session(day: 2, score: 70)

    let snapshot = WidgetSnapshotBuilder.make(from: [older, newest, middle], calendar: calendar)

    #expect(snapshot.lastNight?.id == newest.id)
    #expect(snapshot.lastNight?.score == 90)
    #expect(snapshot.lastNight?.snoringDuration == 1200)
    // Dates round-trip through @Model storage, so compare with a tolerance.
    #expect(abs((snapshot.lastNight?.totalDuration ?? 0) - 7 * 3600) < 0.001)
  }

  @Test func skipsUncachedAndUnfinishedSessions() {
    let valid = session(day: 1, score: 75)
    let uncached = session(day: 2, cached: false)
    let unfinished = session(day: 3, ended: false)

    let snapshot = WidgetSnapshotBuilder.make(from: [valid, uncached, unfinished], calendar: calendar)

    #expect(snapshot.lastNight?.id == valid.id)
    #expect(snapshot.recentDays.count == 1)
  }

  @Test func groupsByCalendarDayAndAveragesScores() {
    let nap = session(day: 5, hour: 14, hours: 1, score: 60)
    let night = session(day: 5, hour: 22, score: 90)

    let snapshot = WidgetSnapshotBuilder.make(from: [nap, night], calendar: calendar)

    #expect(snapshot.recentDays == [.init(date: date(day: 5, hour: 0), averageScore: 75)])
  }

  @Test func keepsSevenMostRecentDaysOldestFirst() {
    let sessions = (1...10).map { session(day: $0, score: 50 + $0) }

    let snapshot = WidgetSnapshotBuilder.make(from: sessions.shuffled(), calendar: calendar)

    #expect(snapshot.recentDays.map(\.averageScore) == [54, 55, 56, 57, 58, 59, 60])
    #expect(snapshot.recentDays.first?.date == date(day: 4, hour: 0))
  }

  @Test func snoringPercentage() {
    let night = WidgetSnapshot.Night(
      id: UUID(), startDate: date(day: 1, hour: 0), endDate: date(day: 1, hour: 10), score: 80, snoringDuration: 3600)
    #expect(night.snoringPercentage == 10)
  }
}

struct WidgetSnapshotStoreTests {
  @Test func roundTripsThroughDisk() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    let snapshot = WidgetSnapshot(
      generatedAt: Date(timeIntervalSince1970: 1_000_000),
      lastNight: .init(
        id: UUID(),
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 25200),
        score: 82,
        snoringDuration: 900),
      recentDays: [.init(date: Date(timeIntervalSince1970: 0), averageScore: 82)])

    try WidgetSnapshotStore.write(snapshot, to: url)

    #expect(WidgetSnapshotStore.read(from: url) == snapshot)
  }

  @Test func missingFileReadsNil() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).json")
    #expect(WidgetSnapshotStore.read(from: url) == nil)
  }
}

struct WidgetDeepLinkTests {
  @Test(arguments: [WidgetDeepLink.startTracking, .session(UUID()), .last7Nights])
  func roundTrips(link: WidgetDeepLink) {
    #expect(WidgetDeepLink(url: link.url) == link)
  }

  @Test func urlsMatchTheWidgetContract() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    #expect(WidgetDeepLink.startTracking.url.absoluteString == "sleepguard://start")
    #expect(WidgetDeepLink.last7Nights.url.absoluteString == "sleepguard://last7nights")
    #expect(WidgetDeepLink.session(id).url.absoluteString == "sleepguard://session/00000000-0000-0000-0000-000000000001")
  }

  @Test(arguments: [
    "https://start",
    "sleepguard://unknown",
    "sleepguard://session/not-a-uuid",
  ])
  func rejectsInvalidURLs(string: String) throws {
    let url = try #require(URL(string: string))
    #expect(WidgetDeepLink(url: url) == nil)
  }
}
