import Testing
@testable import Routing

/// `RouterPath` stack operations and the sheet identity contract.
@MainActor
struct RouterPathTests {
  @Test func navigateBackAndRoot() {
    let router = RouterPath()
    router.navigate(to: .trends)
    router.navigate(to: .last7Nights)
    router.navigate(to: .calendar)
    #expect(router.path.count == 3)

    router.navigateBack()
    #expect(router.path.count == 2)

    router.navigateToRoot()
    #expect(router.path.isEmpty)
  }

  @Test func navigateBackOnEmptyPathIsANoOp() {
    let router = RouterPath()
    router.navigateBack()
    #expect(router.path.isEmpty)
  }

  @Test func sheetIDsAreUnique() {
    let sheets: [SheetDestination] = [.sessionSummary, .profileEditor]
    #expect(Set(sheets.map(\.id)).count == sheets.count)
  }
}
