import FactoryKit
import Foundation
import Models
import Observation

/// App-wide tab selection, pop-to-root signals, and pending deep links.
/// Fake: `FakeTabCoordinator`.
@MainActor
public protocol TabCoordinating: AnyObject, Observable {
  var selectedTab: AppTab { get set }
  var resetSignal: TabResetSignal? { get set }
  var pendingDeepLink: WidgetDeepLink? { get set }
  func selectTab(_ tab: AppTab)
  func open(_ link: WidgetDeepLink)
}

/// Coordinates tab-bar behavior across the app's main tabs.
/// Used to signal "pop to root" when the user taps the already-selected tab.
@MainActor
@Observable
public final class TabCoordinator: TabCoordinating {
  public static let shared = TabCoordinator()

  public var selectedTab: AppTab
  public var resetSignal: TabResetSignal?
  /// A widget deep link waiting for the Statistics tab to route it.
  public var pendingDeepLink: WidgetDeepLink?

  private let appConfig: any AppConfigProviding

  public init(appConfig: any AppConfigProviding = Container.shared.appConfig()) {
    self.appConfig = appConfig
    selectedTab = appConfig.visibleTabsInOrder.first ?? .statistics
  }

  public func selectTab(_ tab: AppTab) {
    if selectedTab == tab {
      resetSignal = TabResetSignal(tab: tab)
    } else {
      selectedTab = tab
    }
  }

  /// Hands a deep link to the Statistics tab. Ignored when remote config hides that tab.
  public func open(_ link: WidgetDeepLink) {
    guard appConfig.visibleTabsInOrder.contains(.statistics) else { return }
    selectedTab = .statistics
    pendingDeepLink = link
  }
}

/// A unique signal indicating that a specific tab should pop to root.
public struct TabResetSignal: Equatable, Sendable {
  public let tab: AppTab
  public let id = UUID()

  public init(tab: AppTab) {
    self.tab = tab
  }
}
