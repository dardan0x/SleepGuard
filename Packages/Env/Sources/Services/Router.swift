import Foundation
import SwiftUI

public enum RouterDestination: Hashable, Sendable {
  case recordingDetail(id: UUID)
  case sessionDetail(id: UUID)
  case liveSession
  case trends
  case last7Nights
  case calendar
}

public enum SheetDestination: Identifiable, Hashable, Sendable {
  case sessionSummary

  public var id: String {
    switch self {
    case .sessionSummary:
      return "sessionSummary"
    }
  }
}

@MainActor
@Observable
public final class RouterPath {
  public var path = NavigationPath()
  public var presentedSheet: SheetDestination?

  public init() {}

  public func navigate(to destination: RouterDestination) {
    path.append(destination)
  }

  public func navigateBack() {
    if !path.isEmpty {
      path.removeLast()
    }
  }

  public func navigateToRoot() {
    path.removeLast(path.count)
  }
}

/// Coordinates tab-bar behavior across the app's main tabs.
/// Used to signal "pop to root" when the user taps the already-selected tab.
@MainActor
@Observable
public final class TabCoordinator {
  public var selectedTab = 0
  public var resetSignal: TabResetSignal?

  public init() {}

  public func selectTab(_ index: Int) {
    if selectedTab == index {
      resetSignal = TabResetSignal(tab: index)
    } else {
      selectedTab = index
    }
  }
}

/// A unique signal indicating that a specific tab should pop to root.
public struct TabResetSignal: Equatable, Sendable {
  public let tab: Int
  public let id = UUID()

  public init(tab: Int) {
    self.tab = tab
  }
}
