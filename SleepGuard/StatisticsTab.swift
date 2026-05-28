import SwiftUI
import SwiftData
import Env
import Models
import SleepSession
import Statistics

struct StatisticsTab: View {
  @State private var routerPath = RouterPath()
  @Environment(TabCoordinator.self) private var tabCoordinator
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(SessionManager.self) private var sessionManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(\.modelContext) private var modelContext

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
      guard newValue != nil else { return }
      if let session = sessionManager.completedSession,
         session.terminationReason != nil {
        autoSaveForceSavedSession(session: session)
      } else {
        routerPath.navigateToRoot()
        routerPath.presentedSheet = .sessionSummary
      }
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == 0 {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  private func autoSaveForceSavedSession(session: SleepSession) {
    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    modelContext.insert(session)

    do {
      try modelContext.save()
    } catch {
      routerPath.navigateToRoot()
      routerPath.presentedSheet = .sessionSummary
      return
    }

    sessionManager.completedSession = nil

    if userPreferences.syncToHealthKit {
      Task {
        healthKitSync.checkAuthorizationStatus()
        await healthKitSync.sync(session: session)
      }
    }
  }
}
