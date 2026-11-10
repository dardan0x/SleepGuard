import Env
import Recordings
import Routing
import SleepSession
import Statistics
import SwiftUI

extension View {
  /// Sheets live in a separate window without the tab's environment.
  /// Injects a fresh RouterPath so sheet content can present its own
  /// navigation stack. Services resolve through the Factory container
  /// (`@Injected`) and need no environment forwarding.
  func withEnvironments() -> some View {
    environment(RouterPath())
  }

  func withAppRouter() -> some View {
    navigationDestination(for: RouterDestination.self) { destination in
      switch destination {
      case let .recordingDetail(id):
        SessionDetailView(sessionID: id)
      case let .sessionDetail(id):
        SessionDetailView(sessionID: id)
      case .liveSession:
        SleepSessionView()
      case .trends:
        TrendsView()
      case .last7Nights:
        Last7NightsView()
      case .calendar:
        CalendarView()
      }
    }
  }
}
