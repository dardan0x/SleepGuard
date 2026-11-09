import Foundation
import ModelsTestSupport
import SwiftData
import Testing
@testable import Models

@MainActor
struct TestStoreTests {
  @Test func insertedEventsAreReadableThroughTheSession() throws {
    let store = try TestStore()
    let start = TestCalendar.date(day: 1, hour: 23)
    let session = try store.insert(
      .fixture(start: start),
      events: [.fixture(at: start.addingTimeInterval(600), duration: 90)])

    let fetched = try store.context.fetch(FetchDescriptor<SleepSession>())
    #expect(fetched.count == 1)
    #expect(session.events?.count == 1)
    #expect(session.events?.first?.session === session)
    #expect(session.snoringDuration == 90)
  }
}
