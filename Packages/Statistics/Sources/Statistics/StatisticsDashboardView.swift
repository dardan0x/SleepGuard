import SwiftUI
import SwiftData
import Env
import Models
import DesignSystem

@MainActor
public struct StatisticsDashboardView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var viewState: ViewState = .loading

  public init() {}

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        Color.clear
          .task {
            loadState()
          }
      case .empty:
        StatisticsEmptyView(theme: theme) {
          routerPath.navigate(to: .liveSession)
        }
      case .loaded(let session, let recentSessions):
        StatisticsLoadedView(
          session: session,
          recentSessions: recentSessions,
          theme: theme
        ) {
          routerPath.navigate(to: .liveSession)
        }
      case .error:
        StatisticsErrorView(theme: theme) {
          loadState()
        }
      }
    }
    .background(theme.backgroundColor.ignoresSafeArea())
    .onChange(of: sessions) { _, _ in
      loadState()
    }
  }

  private func loadState() {
    if let latest = sessions.first {
      let recent = Array(sessions.prefix(7))
      viewState = .loaded(session: latest, recentSessions: recent)
    } else {
      viewState = .empty
    }
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(session: SleepSession, recentSessions: [SleepSession])
    case error
  }
}

// MARK: - Empty State

@MainActor
struct StatisticsEmptyView: View {
  let theme: Theme
  let onStartRecording: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerSection

        VStack(spacing: 16) {
          ZStack {
            Circle()
              .fill(theme.primaryColor.opacity(0.15))
              .frame(width: 80, height: 80)

            Image(systemName: "moon.fill")
              .font(.system(size: 32))
              .foregroundStyle(theme.primaryColor)
          }

          VStack(spacing: 4) {
            Text("Ready to Sleep?")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(theme.labelColor)

            Text("Start a recording to analyze your snoring")
              .font(.system(size: 15))
              .foregroundStyle(theme.secondaryLabelColor)
              .multilineTextAlignment(.center)
          }

          Button {
            onStartRecording()
          } label: {
            Text("Start Recording")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.primaryColor)
              .clipShape(Capsule())
          }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(theme.surfaceColor)
        .cornerRadius(16)
      }
      .padding(20)
    }
  }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Sleep Statistics")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.labelColor)

      Text("Track and improve your sleep quality")
        .font(.system(size: 15))
        .foregroundStyle(theme.secondaryLabelColor)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Loaded State

@MainActor
struct StatisticsLoadedView: View {
  let session: SleepSession
  let recentSessions: [SleepSession]
  let theme: Theme
  let onStartRecording: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        headerSection

        scoreCard

        statsGrid

        if !recentSessions.isEmpty {
          sparklineCard
        }

        Button {
          onStartRecording()
        } label: {
          Text("Start Recording")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.primaryColor)
            .clipShape(Capsule())
        }
      }
      .padding(20)
    }
  }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Sleep Statistics")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.labelColor)

      Text("Track and improve your sleep quality")
        .font(.system(size: 15))
        .foregroundStyle(theme.secondaryLabelColor)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var scoreCard: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        SleepScoreGauge(score: session.sleepScore, theme: theme, size: 110)

        VStack(alignment: .leading, spacing: 6) {
          Text("Last Night")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.secondaryLabelColor)
            .textCase(.uppercase)

          Text(dateString)
            .font(.system(size: 15))
            .foregroundStyle(theme.labelColor)

          Text(scoreLabel)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(scoreColor)
        }

        Spacer()
      }
    }
    .padding(20)
    .background(theme.surfaceColor)
    .cornerRadius(16)
  }

  private var statsGrid: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    return LazyVGrid(columns: columns, spacing: 12) {
      StatCard(
        icon: "clock.fill",
        title: "Duration",
        value: durationString,
        theme: theme,
        iconColor: theme.primaryColor
      )
      StatCard(
        icon: "waveform.path",
        title: "Snoring",
        value: String(format: "%.1f%%", session.snoringPercentage),
        theme: theme,
        iconColor: Color.orange
      )
      StatCard(
        icon: "exclamationmark.triangle.fill",
        title: "Events",
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: Color.red
      )
      StatCard(
        icon: "number",
        title: "Events / Hour",
        value: String(format: "%.1f", session.eventsPerHour),
        theme: theme,
        iconColor: theme.primaryColor
      )
      StatCard(
        icon: "speaker.wave.2.fill",
        title: "Avg dB",
        value: String(format: "%.1f dB", session.averageDB),
        theme: theme,
        iconColor: theme.primaryColor
      )
      StatCard(
        icon: "speaker.wave.3.fill",
        title: "Peak dB",
        value: String(format: "%.1f dB", session.peakDB),
        theme: theme,
        iconColor: Color.red
      )
    }
  }

  private var sparklineCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Last 7 Nights")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.secondaryLabelColor)
        .textCase(.uppercase)

      let data = recentSessions.map {
        SleepSparkline.DataPoint(date: $0.startDate, score: $0.sleepScore)
      }

      SleepSparkline(data: data, theme: theme)
    }
    .padding(20)
    .background(theme.surfaceColor)
    .cornerRadius(16)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: session.startDate)
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }

  private var scoreColor: Color {
    switch session.sleepScore {
    case 80...100:
      theme.secondaryColor
    case 50 ..< 80:
      Color.orange
    default:
      Color.red
    }
  }

  private var scoreLabel: String {
    switch session.sleepScore {
    case 80...100:
      "Great sleep"
    case 50 ..< 80:
      "Moderate snoring"
    default:
      "Heavy snoring"
    }
  }
}

// MARK: - Error State

@MainActor
struct StatisticsErrorView: View {
  let theme: Theme
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.secondaryLabelColor)

      Text("Something went wrong")
        .font(.headline)
        .foregroundStyle(theme.labelColor)

      Button("Try Again") {
        onRetry()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(theme.primaryColor)
    }
  }
}
