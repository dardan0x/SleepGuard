import Testing
@testable import Recordings

struct SessionGrouperTests {
  @Test func emptyInputProducesNoSections() {
    #expect(SessionGrouper.groupSessions([]).isEmpty)
  }
}
