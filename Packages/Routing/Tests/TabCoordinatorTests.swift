import Config
import ConfigTestSupport
import Foundation
import Models
import Testing
@testable import Routing

/// App-wide tab state (moved from Env in F27-T11): first visible tab, deep
/// links to Statistics, and links that wait while something blocks them.
@MainActor
struct TabCoordinatorTests {
  private func config(hiding hidden: AppTab) -> AppConfig {
    let config = AppConfig.isolated()
    let tabs = AppTab.allCases.enumerated().map { TabConfig(tab: $1, isVisible: $1 != hidden, order: $0) }
    config.apply(flags: [:], tabs: tabs, learnTab: nil, updateGate: .none)
    return config
  }

  @Test func tabCoordinatorStartsOnTheFirstVisibleTab() {
    let coordinator = TabCoordinator(appConfig: config(hiding: .statistics))
    #expect(coordinator.selectedTab != .statistics)
  }

  @Test func deepLinkIsIgnoredWhenStatisticsIsHidden() {
    let coordinator = TabCoordinator(appConfig: config(hiding: .statistics))

    coordinator.open(.startTracking)

    #expect(coordinator.pendingDeepLink == nil)
  }

  @Test func deepLinkRoutesToStatisticsWhenVisible() {
    let coordinator = TabCoordinator(appConfig: AppConfig.isolated())
    coordinator.selectedTab = .settings

    coordinator.open(.last7Nights)

    #expect(coordinator.selectedTab == .statistics)
    #expect(coordinator.pendingDeepLink == .last7Nights)
  }

  @Test func aBlockedDeepLinkWaitsInsteadOfBeingDropped() {
    let coordinator = TabCoordinator(appConfig: AppConfig.isolated())
    coordinator.open(.last7Nights)

    #expect(coordinator.takePendingDeepLink(blocked: true) == nil)
    #expect(coordinator.pendingDeepLink == .last7Nights)

    #expect(coordinator.takePendingDeepLink(blocked: false) == .last7Nights)
    #expect(coordinator.pendingDeepLink == nil)
    #expect(coordinator.takePendingDeepLink(blocked: false) == nil)
  }
}
