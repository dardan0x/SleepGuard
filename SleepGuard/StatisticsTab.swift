import SwiftUI
import SwiftData
import Env
import Models
import Personalization
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
      VStack(spacing: 0) {
        ProfilePromptCard {
          routerPath.presentedSheet = .profileEditor
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)

        StatisticsDashboardView()
          .withAppRouter()
      }
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
      case .profileEditor:
        if let profile = fetchOrCreateProfile() {
          ProfileEditorView(
            profile: profile,
            onComplete: {
              routerPath.presentedSheet = nil
              UserPreferences.shared.hasCompletedProfile = true
            },
            onDismiss: {
              routerPath.presentedSheet = nil
            }
          )
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
      if let signal, signal.tab == .statistics {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  private func fetchOrCreateProfile() -> UserProfile? {
    let descriptor = FetchDescriptor<UserProfile>()
    if let existing = try? modelContext.fetch(descriptor).first {
      return existing
    }
    let profile = UserProfile()
    modelContext.insert(profile)
    return profile
  }

  private func autoSaveForceSavedSession(session: SleepSession) {
    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    modelContext.insert(session)

    // Cache AFTER insertion so SwiftData tracks the mutations
    session.cachedSleepScore = session.sleepScore
    session.cachedSnoringDuration = session.snoringDuration
    session.hasCachedScore = true

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
