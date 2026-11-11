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
