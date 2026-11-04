import SwiftUI
import SwiftData
import AudioEngine
import Models
import Env
import DesignSystem

@MainActor
public struct SessionSummaryView: View {
  public let session: SleepSession

  public init(session: SleepSession) {
    self.session = session
  }

  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(AppConfig.self) private var appConfig
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var showShortSessionAlert = false
  @State private var showSaveErrorAlert = false

  public var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        SessionSummaryStats(session: session)

        MelodyGapsBannerView(session: session)

        LowBatteryBannerView(session: session)

        SessionSummaryTimeline(session: session)

        SessionSummaryActions(onSave: saveSession, onDiscard: discardSession)
      }
      .padding(24)
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showShortSessionAlert) {
      Button(Strings.actionOk, role: .cancel) { }
    } message: {
      Text(String(format: Strings.sessionSummaryTooShortInfoFormat, Int(SleepSession.minimumSaveDuration / 60)))
    }
    .alert(Strings.saveFailed, isPresented: $showSaveErrorAlert) {
      Button(Strings.actionOk, role: .cancel) { }
    } message: {
      Text(Strings.unableToSaveTheSession)
    }
  }

  // MARK: - Save / discard

  private func saveSession() {
    if session.totalDuration < SleepSession.minimumSaveDuration {
      showShortSessionAlert = true
      return
    }

    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    modelContext.insert(session)

    // Cache AFTER insertion so SwiftData tracks the mutations.
    // Use the current remote config so the cached score reflects the
    // active formula if the session is later shown in a list view.
    session.cachedSleepScore = session.sleepScore(using: appConfig.sleepScoreConfig)
    session.cachedSnoringDuration = session.snoringDuration
    session.hasCachedScore = true

    do {
      try modelContext.save()
    } catch {
      showSaveErrorAlert = true
      return
    }

    PendingSessionStore.shared.clearPending()
    SessionCheckpointStore.shared.clear()

    Task {
      await StorageLimitEnforcer.shared.enforceLimits(modelContext: modelContext)
    }

    if userPreferences.syncToHealthKit {
      Task {
        healthKitSync.checkAuthorizationStatus()
        await healthKitSync.sync(session: session)
      }
    }

    dismiss()
  }

  private func discardSession() {
    sessionManager.discardCompletedSession()
    dismiss()
  }
}
