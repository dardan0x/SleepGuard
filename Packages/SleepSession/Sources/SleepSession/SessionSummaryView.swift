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
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          scoreSection

          statsGrid

          Spacer(minLength: 24)

          actionButtons
        }
        .padding(24)
      }
      .background(theme.backgroundColor.ignoresSafeArea())
      .navigationTitle("Sleep Summary")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            discardSession()
          }
          .foregroundStyle(theme.secondaryLabelColor)
        }
      }
    }
  }

  // MARK: - Subviews

  private var scoreSection: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .stroke(theme.surfaceColor, lineWidth: 12)
          .frame(width: 140, height: 140)

        Circle()
          .trim(from: 0, to: CGFloat(session.sleepScore) / 100)
          .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
          .frame(width: 140, height: 140)
          .rotationEffect(.degrees(-90))

        VStack(spacing: 2) {
          Text("\(session.sleepScore)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(theme.labelColor)

          Text("Sleep Score")
            .font(.caption)
            .foregroundStyle(theme.secondaryLabelColor)
        }
      }

      Text(scoreLabel)
        .font(.headline)
        .foregroundStyle(scoreColor)
    }
    .padding(.top, 16)
  }

  private var statsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
      StatCard(title: "Duration", value: durationString, theme: theme)
      StatCard(title: "Snoring", value: String(format: "%.1f%%", session.snoringPercentage), theme: theme)
      StatCard(title: "Events", value: "\(session.eventsCount)", theme: theme)
      StatCard(title: "Events / Hour", value: String(format: "%.1f", session.eventsPerHour), theme: theme)
      StatCard(title: "Avg dB", value: String(format: "%.1f dB", session.averageDB), theme: theme)
      StatCard(title: "Peak dB", value: String(format: "%.1f dB", session.peakDB), theme: theme)
    }
  }

  private var actionButtons: some View {
    VStack(spacing: 12) {
      Button {
        saveSession()
      } label: {
        Text("Save Session")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(theme.primaryColor)
          .cornerRadius(12)
      }

      Button {
        discardSession()
      } label: {
        Text("Discard")
          .font(.headline)
          .foregroundStyle(theme.secondaryLabelColor)
          .frame(maxWidth: .infinity)
          .padding()
          .background(theme.surfaceColor)
          .cornerRadius(12)
      }
    }
  }

  // MARK: - Helpers

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private var scoreColor: Color {
    switch session.sleepScore {
    case 80...100: return theme.secondaryColor
    case 50..<80: return Color.orange
    default: return Color.red
    }
  }

  private var scoreLabel: String {
    switch session.sleepScore {
    case 80...100: return "Great Sleep"
    case 50..<80: return "Fair Sleep"
    default: return "Poor Sleep"
    }
  }

  private func saveSession() {
    modelContext.insert(session)
    if let events = session.events {
      for event in events {
        modelContext.insert(event)
      }
    }
    try? modelContext.save()
    dismiss()
  }

  private func discardSession() {
    dismiss()
  }
}

// MARK: - StatCard

@MainActor
private struct StatCard: View {
  let title: String
  let value: String
  let theme: Theme

  var body: some View {
    VStack(spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(theme.secondaryLabelColor)
        .textCase(.uppercase)

      Text(value)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.labelColor)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, minHeight: 80)
    .padding(12)
    .background(theme.surfaceColor)
    .cornerRadius(12)
  }
}
