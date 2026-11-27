import FactoryKit
import FactoryTesting
import Models
import RoutingTestSupport
import Testing
@testable import Routing

/// The container hands out the fake when a test registers it.
@MainActor
@Suite(.container)
struct TabCoordinatorOverrideTests {
  @Test func tabCoordinatorOverride() {
    let tabs = FakeTabCoordinator()
    Container.shared.tabCoordinator.register { tabs }

    Container.shared.tabCoordinator().selectTab(.statistics)

    #expect(tabs.resetSignal?.tab == .statistics) // already selected → pop to root
  }
}
