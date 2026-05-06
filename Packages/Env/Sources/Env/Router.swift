import Foundation
import SwiftUI

public enum RouterDestination: Hashable, Sendable {
  case recordingDetail(id: UUID)
  case sessionDetail(id: UUID)
}

public enum SheetDestination: Identifiable, Hashable, Sendable {
  case sessionSummary
  case liveSession

  public var id: String {
    switch self {
    case .sessionSummary:
      return "sessionSummary"
    case .liveSession:
      return "liveSession"
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
