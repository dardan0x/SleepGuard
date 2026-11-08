import Env
import Foundation
import Models
import SwiftData

/// Turns a widget deep link into a push on the Statistics tab's stack.
enum DeepLinkRouter {
  static func route(_ link: WidgetDeepLink, routerPath: RouterPath, modelContext: ModelContext) {
    routerPath.navigateToRoot()
    switch link {
    case .startTracking:
      routerPath.navigate(to: .liveSession)
    case let .session(id):
      // A session deleted after the widget last refreshed falls back to the dashboard.
      var descriptor = FetchDescriptor<SleepSession>(predicate: #Predicate { $0.id == id })
      descriptor.fetchLimit = 1
      guard let count = try? modelContext.fetchCount(descriptor), count > 0 else { return }
      routerPath.navigate(to: .sessionDetail(id: id))
    case .last7Nights:
      routerPath.navigate(to: .last7Nights)
    }
  }
}
