import SwiftUI
import Env
import SleepSession
import Statistics

struct StatisticsTab: View {
  @State private var routerPath = RouterPath()
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(SessionManager.self) private var sessionManager

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }
    )) {
      StatisticsDashboardView()
        .withAppRouter()
    }
    .sheet(
      item: Binding(
        get: { routerPath.presentedSheet },
        set: { routerPath.presentedSheet = $0 }
      ),
      onDismiss: {
        if sessionManager.completedSession != nil {
          sessionManager.completedSession = nil
        }
      }
    ) { destination in
      switch destination {
      case .sessionSummary:
        if let session = sessionManager.completedSession {
          SessionSummaryView(session: session)
            .withEnvironments()
        }
      }
    }
    .onAppear {
      if userPreferences.presentRecordingAfterOnboarding {
        userPreferences.presentRecordingAfterOnboarding = false
        routerPath.navigate(to: .liveSession)
      }
    }
    .onChange(of: sessionManager.completedSession) { _, newValue in
      if newValue != nil {
        routerPath.navigateToRoot()
        routerPath.presentedSheet = .sessionSummary
      }
    }
    .environment(routerPath)
  }
}
