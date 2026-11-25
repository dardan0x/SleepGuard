import Foundation
import Models
import Observation
import Routing

/// Scriptable `TabCoordinating`.
@MainActor
@Observable
public final class FakeTabCoordinator: TabCoordinating {
  public var selectedTab: AppTab
  public var resetSignal: TabResetSignal?
  public var pendingDeepLink: WidgetDeepLink?

  public init(selectedTab: AppTab = .statistics) {
    self.selectedTab = selectedTab
  }

  public func selectTab(_ tab: AppTab) {
    if selectedTab == tab {
      resetSignal = TabResetSignal(tab: tab)
    } else {
      selectedTab = tab
    }
  }

  public func open(_ link: WidgetDeepLink) {
    selectedTab = .statistics
    pendingDeepLink = link
  }

  public func takePendingDeepLink(blocked: Bool) -> WidgetDeepLink? {
    guard !blocked, let link = pendingDeepLink else { return nil }
    pendingDeepLink = nil
    return link
  }
}
