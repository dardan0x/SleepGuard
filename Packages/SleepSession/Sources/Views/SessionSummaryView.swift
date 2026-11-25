import AudioEngine
import Config
import DesignSystem
import Env
import FactoryKit
public import Models
import SwiftData
public import SwiftUI

@MainActor
public struct SessionSummaryView: View {
  public let session: SleepSession

  public init(session: SleepSession) {
    self.session = session
  }

  @Injected(\.sessionManager) private var sessionManager
  @Injected(\.sessionCommitter) private var sessionCommitter
  @Injected(\.appConfig) private var appConfig
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var activeAlert: SummaryAlert?

  public var body: some View {
    // The shared summary content (ADR 0006).
    let night = session.night
    SessionSummaryContent(
      night: night, summary: night.summary(using: appConfig.sleepScoreConfig),
      onSave: saveSession, onDiscard: discardSession)
      .alert(Strings.sessionSummaryTooShortTitle, isPresented: isPresented(.tooShort)) {
        Button(Strings.actionOk, role: .cancel) {}
      } message: {
        Text(String(format: Strings.sessionSummaryTooShortInfoFormat, Int(SleepSession.minimumSaveDuration / 60)))
      }
      .alert(Strings.saveFailed, isPresented: isPresented(.saveFailed)) {
        Button(Strings.actionOk, role: .cancel) {}
      } message: {
        Text(Strings.unableToSaveTheSession)
      }
  }

  /// Binding for the alert modifiers, derived from the enum state so the
  /// modifier forms (and their rendering) are unchanged.
  private func isPresented(_ alert: SummaryAlert) -> Binding<Bool> {
    Binding(
      get: { activeAlert == alert },
      set: { isActive in
        if !isActive {
          activeAlert = nil
        }
      })
  }

  // MARK: - Save / discard

  private func saveSession() {
    if session.totalDuration < SleepSession.minimumSaveDuration {
      activeAlert = .tooShort
      return
    }

    do {
      try sessionCommitter.commit(session, in: modelContext)
    } catch {
      activeAlert = .saveFailed
      return
    }

    dismiss()
  }

  private func discardSession() {
    sessionManager.discardCompletedSession()
    dismiss()
  }
}

enum SummaryAlert {
  case tooShort
  case saveFailed
}
