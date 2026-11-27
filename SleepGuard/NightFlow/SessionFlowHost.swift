import Config
import Models
import os
import Personalization
import Platform
import Routing
import Services
import SleepCore
import SleepLogging
import SleepSession
import SleepStore
import SwiftData
import SwiftUI

/// The app-level end of a night, independent of which tabs remote config shows:
/// crash recovery, the summary sheet, the low-battery auto-save, and the
/// prompts that share the root's one presentation slot (notification soft-ask,
/// morning briefing). `RootPresentationPolicy` decides what shows when.
struct SessionFlowHost: ViewModifier {
  @State private var sessionManager = SessionManager.shared
  @State private var briefingController = BriefingController()
  @State private var presented: RootPresentation?
  /// What the sheet showed last; `presented` is already `nil` when it closes.
  @State private var shown: RootPresentation?
  @State private var softAskDue = false
  /// A force-saved night whose auto-save failed: the user saves it by hand.
  @State private var autoSaveFailedID: UUID?
  @Environment(\.modelContext) private var modelContext
  private let sessionCommitter = SessionCommitter.shared
  private let tabCoordinator = TabCoordinator.shared
  private let appConfig = AppConfig.shared
  private let userPreferences = UserPreferences.shared
  private let notificationPermissions = NotificationPermissionManager.shared

  func body(content: Content) -> some View {
    content
      .task { await launch() }
      .onChange(of: sessionManager.completedSession) {
        closeSummaryIfResolved()
        autoSaveIfForceSaved()
        presentNext()
      }
      .onChange(of: sessionManager.isRecording) { presentNext() }
      .onChange(of: sessionManager.isLiveSessionVisible) { presentNext() }
      .sheet(item: $presented, onDismiss: didDismiss) { presentation in
        switch presentation {
        case let .sessionSummary(id):
          if let session = sessionManager.completedSession, session.id == id {
            SessionSummaryView(session: session)
              .withEnvironments()
          }
        case .notificationSoftAsk:
          NotificationSoftAskView(onClose: { presented = nil })
            .withEnvironments()
        case .briefing:
          if let briefing = briefingController.current {
            BriefingSheet(presented: briefing, controller: briefingController)
          }
        }
      }
  }

  /// Recovery first, so a night left by a crash outranks the prompts.
  private func launch() async {
    // The briefing below reads the profile and the survey answers.
    await ProfileStore.shared.load()
    await LifestyleLogStore.shared.load()
    if let night = SessionCheckpointStore.shared.loadIfPresent() {
      let recovered = NightRecord.make(from: night)
      recovered.refreshSummary(using: appConfig.sleepScoreConfig)
      sessionManager.completedSession = recovered
    } else {
      PendingSessionStore.shared.cleanupIfNeeded()
    }
    autoSaveIfForceSaved()
    briefingController.prepareIfDue(modelContext: modelContext)
    softAskDue = await isNotificationSoftAskDue()
    presentNext()
  }

  private var requests: [RootPresentation] {
    var requests: [RootPresentation] = []
    if let session = sessionManager.completedSession,
       session.endReason == .stopped || autoSaveFailedID == session.id
    {
      requests.append(.sessionSummary(id: session.id))
    }
    if softAskDue { requests.append(.notificationSoftAsk) }
    if let briefing = briefingController.current { requests.append(.briefing(id: briefing.id)) }
    return requests
  }

  private func presentNext() {
    guard let next = RootPresentationPolicy.next(
      requests: requests,
      // `shown` stays set until the sheet has finished closing, so nothing new
      // is presented into a sheet that is still on its way out.
      current: shown,
      isRecording: sessionManager.isRecording,
      isInLiveSession: sessionManager.isLiveSessionVisible) else { return }
    if case .sessionSummary = next {
      // The live session screen sits on the Statistics stack; leave it.
      tabCoordinator.resetSignal = TabResetSignal(tab: .statistics)
    }
    shown = next
    presented = next
  }

  /// Discarding clears the night before the summary dismisses itself, which
  /// empties the sheet's content and leaves its own dismiss with nothing to
  /// close. The host closes the summary as soon as its night is resolved.
  private func closeSummaryIfResolved() {
    guard case let .sessionSummary(id) = presented, sessionManager.completedSession?.id != id else { return }
    presented = nil
  }

  /// Clears the request the closed sheet answered, then shows the next one.
  private func didDismiss() {
    switch shown {
    case .sessionSummary:
      // Saved, discarded or swiped away: the night is no longer pending here.
      sessionManager.completedSession = nil
    case .notificationSoftAsk:
      softAskDue = false
    case .briefing:
      briefingController.markShown()
    case nil:
      break
    }
    shown = nil
    presentNext()
  }

  /// A night stopped by the app (low battery) saves itself. If saving fails,
  /// the summary is offered instead so the night isn't lost.
  private func autoSaveIfForceSaved() {
    guard let session = sessionManager.completedSession, session.endReason != .stopped,
          autoSaveFailedID != session.id else { return }
    do {
      try sessionCommitter.commit(session, in: modelContext)
      sessionManager.completedSession = nil
    } catch {
      Log.session.error("Auto-save of a force-saved night failed: \(String(describing: error), privacy: .public)")
      autoSaveFailedID = session.id
    }
  }

  /// After a few app opens, once, when notifications are on remotely and the
  /// user hasn't been asked.
  private func isNotificationSoftAskDue() async -> Bool {
    guard appConfig.isEnabled(.notifications), !userPreferences.notificationSoftAskDismissed,
          userPreferences.appOpenCount >= 3 else { return false }
    await notificationPermissions.refreshStatus()
    return notificationPermissions.authorizationStatus == .notDetermined
  }
}
