import SwiftUI
import SwiftData
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
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  public var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        completionHeader

        scoreSection

        statsGrid

        timelineSection

        actionButtons
      }
      .padding(24)
    }
    .background(theme.bgSecondary.ignoresSafeArea())
  }

  private var completionHeader: some View {
    VStack(spacing: 8) {
      Text("SESSION COMPLETE")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.scoreGreen)
        .tracking(2)

      Text("You slept \(durationString)")
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
        title: "Snoring",
        value: String(format: "%.0f%%", session.snoringPercentage),
        theme: theme,
        iconColor: theme.scoreAmber
      )
      StatCard(
        icon: "bolt.fill",
        title: "Events",
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: theme.scoreAmber
      )
      StatCard(
        icon: "speaker.wave.3.fill",
        title: "Peak",
        value: String(format: "%.0fdB", session.peakDB),
        theme: theme,
        iconColor: theme.accent
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
      Button {
        saveSession()
      } label: {
        Text("Save Session")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(theme.accent)
          .clipShape(Capsule())
      }

      Button {
        discardSession()
      } label: {
        Text("Discard")
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
    return String(format: "%dh %02dm", hours, minutes)
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private func saveSession() {
    modelContext.insert(session)
    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    try? modelContext.save()

    if UserPreferences.shared.syncToHealthKit {
      Task {
        await HealthKitSync.shared.sync(session: session)
      }
    }

    dismiss()
  }

  private func discardSession() {
    sessionManager.discardCompletedSession()
    dismiss()
  }
}
