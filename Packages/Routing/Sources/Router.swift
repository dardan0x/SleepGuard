public import SwiftUI

public enum RouterDestination: Hashable, Sendable {
  case recordingDetail(id: UUID)
  case sessionDetail(id: UUID)
  case liveSession
  case trends
  case last7Nights
  case calendar
}

/// A tab's own sheets. App-level modals (the end-of-night summary, prompts)
/// are `RootPresentation`s, presented by the app root.
public enum SheetDestination: Identifiable, Hashable, Sendable {
  case profileEditor

  public var id: String {
    switch self {
    case .profileEditor:
      "profileEditor"
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
