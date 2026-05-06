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
          routerPath.presentedSheet = .liveSession
        }
      case .loaded(let session):
        StatisticsLoadedView(session: session, theme: theme) {
          routerPath.presentedSheet = .liveSession
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
      viewState = .loaded(session: latest)
    } else {
      viewState = .empty
    }
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(session: SleepSession)
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
  let theme: Theme
  let onStartRecording: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        headerSection

        lastNightCard

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

  private var lastNightCard: some View {
    VStack(spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Last Night")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.secondaryLabelColor)
            .textCase(.uppercase)

          Text(dateString)
            .font(.system(size: 15))
            .foregroundStyle(theme.labelColor)
        }

        Spacer()

        Text("\(session.sleepScore)")
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .foregroundStyle(scoreColor)
      }

      Divider()
        .background(theme.secondaryLabelColor.opacity(0.2))

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatRow(title: "Duration", value: durationString)
        StatRow(title: "Snoring", value: String(format: "%.1f%%", session.snoringPercentage))
        StatRow(title: "Events", value: "\(session.eventsCount)")
        StatRow(title: "Avg dB", value: String(format: "%.1f dB", session.averageDB))
      }
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
    case 80...100: return theme.secondaryColor
    case 50..<80: return Color.orange
    default: return Color.red
    }
  }

  @MainActor
  private struct StatRow: View {
    let title: String
    let value: String
    @Environment(Theme.self) private var theme

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .foregroundStyle(theme.secondaryLabelColor)

        Text(value)
          .font(.system(size: 17, weight: .semibold, design: .rounded))
          .foregroundStyle(theme.labelColor)
      }
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
