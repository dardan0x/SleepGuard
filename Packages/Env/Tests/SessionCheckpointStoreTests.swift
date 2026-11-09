import Testing
@testable import Env

@MainActor
struct SessionCheckpointStoreTests {
  @Test func loadAfterClearReturnsNil() {
    let store = SessionCheckpointStore.shared
    store.clear()
    #expect(store.loadIfPresent() == nil)
  }
}
