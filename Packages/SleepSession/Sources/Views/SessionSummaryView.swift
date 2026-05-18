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
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var showShortSessionAlert = false
  @State private var showSaveErrorAlert = false

  public var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        completionHeader

        scoreSection

        statsGrid

        MelodyGapsBannerView(session: session)

        timelineSection

        actionButtons
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

  private var completionHeader: some View {
    VStack(spacing: 8) {
      Text(Strings.sessionSummaryTitle)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.scoreGreen)
        .tracking(2)

      Text(String(format: Strings.sessionSummaryYouSleptFormat, durationString))
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
    }
    .padding(.top, 16)
  }

  private var scoreSection: some View {
    SleepScoreGauge(score: session.sleepScore, theme: theme, size: 160)
  }

  private var statsGrid: some View {
    HStack(spacing: 12) {
      StatCard(
        icon: "percent",
        title: Strings.sessionSummaryStatSnoring,
        value: String(format: "%.0f%%", session.snoringPercentage),
        theme: theme,
        iconColor: theme.scoreAmber
      )
      StatCard(
        icon: "bolt.fill",
        title: Strings.recordingsDetailEventsLabel,
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: theme.scoreAmber
      )
    }
  }

  private var timelineSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      SnoringTimelineView(session: session, theme: theme)

      HStack {
        Text(timeString(session.startDate))
          .font(.caption2)
          .foregroundStyle(theme.textTertiary)

        Spacer()

        if let endDate = session.endDate {
          Text(timeString(endDate))
            .font(.caption2)
            .foregroundStyle(theme.textTertiary)
        }
      }
    }
  }

  private var actionButtons: some View {
    VStack(spacing: 12) {
      ZStack {
        // Outer soft halo
        Capsule()
          .fill(theme.accent.opacity(0.12))
          .frame(maxWidth: .infinity)
          .frame(height: 96)
          .blur(radius: 20)
          .offset(y: 6)

        // Inner concentrated glow
        Capsule()
          .fill(
            LinearGradient(
              colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.0)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(maxWidth: .infinity)
          .frame(height: 76)
          .blur(radius: 10)
          .offset(y: 8)

        Button {
          saveSession()
        } label: {
          Text(Strings.actionSaveSession)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
              ZStack {
                Color(hex: "#1E1D1E")
                Capsule()
                  .stroke(
                    LinearGradient(
                      colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                      startPoint: .leading,
                      endPoint: .trailing
                    ),
                    lineWidth: 1
                  )
              }
            )
            .clipShape(Capsule())
        }
      }

      Button {
        discardSession()
      } label: {
        Text(Strings.actionDiscard)
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
    }
  }

  // MARK: - Helpers

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }

  private func timeString(_ date: Date) -> String {
    DateFormatters.timeWithPeriod.string(from: date)
  }

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

    do {
      try modelContext.save()
    } catch {
      showSaveErrorAlert = true
      return
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
