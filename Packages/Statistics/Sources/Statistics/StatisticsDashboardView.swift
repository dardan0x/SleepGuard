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
          .task { loadState() }
      case .empty:
        StatisticsEmptyView(theme: theme) {
          routerPath.navigate(to: .liveSession)
        }
      case .loaded(let session, let recentSessions):
        StatisticsLoadedView(
          session: session,
          recentSessions: recentSessions,
          theme: theme,
          onStartRecording: {
            routerPath.navigate(to: .liveSession)
          },
          onViewTrends: {
            routerPath.navigate(to: .trends)
          }
        )
      case .error:
        StatisticsErrorView(theme: theme) {
          loadState()
        }
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
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
              .fill(theme.accent.opacity(0.15))
              .frame(width: 80, height: 80)

            Image(systemName: "moon.fill")
              .font(.system(size: 32))
              .foregroundStyle(theme.accent)
          }

          VStack(spacing: 4) {
            Text("Ready to Sleep?")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(theme.textPrimary)

            Text("Start a recording to analyze your snoring")
              .font(.system(size: 15))
              .foregroundStyle(theme.textSecondary)
              .multilineTextAlignment(.center)
          }

          Button {
            onStartRecording()
          } label: {
            Text("Start Recording")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 52)
              .background(theme.accent)
              .clipShape(Capsule())
          }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusCard)
      }
      .padding(20)
    }
  }

  private var headerSection: some View {
    HStack {
      Text("Statistics")
        .font(.system(size: 32, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        // Calendar action
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
          Text("Calendar")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.accent)
        .clipShape(Capsule())
      }
    }
  }
}

// MARK: - Loaded State

@MainActor
struct StatisticsLoadedView: View {
  let session: SleepSession
  let recentSessions: [SleepSession]
  let theme: Theme
  let onStartRecording: () -> Void
  let onViewTrends: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerSection

        weekSelector

        SleepScoreGauge(score: session.sleepScore, theme: theme, size: 150)

        VStack(spacing: 4) {
          Text("LAST NIGHT")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
            .tracking(1)

          Text("\(dateString) · \(timeRangeString)")
            .font(.system(size: 15))
            .foregroundStyle(theme.textSecondary)
        }

        statsGrid

        if !recentSessions.isEmpty {
          chartSection
        }

        Button {
          onStartRecording()
        } label: {
          HStack(spacing: 8) {
            Circle()
              .fill(theme.scoreGreen)
              .frame(width: 8, height: 8)
            Text("Start Recording")
          }
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(theme.accent)
          .clipShape(Capsule())
        }
      }
      .padding(20)
    }
  }

  private var headerSection: some View {
    HStack {
      Text("Statistics")
        .font(.system(size: 32, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        // Calendar action
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
          Text("Calendar")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.accent)
        .clipShape(Capsule())
      }
    }
  }

  private var weekSelector: some View {
    VStack(spacing: 8) {
      HStack {
        Text("THIS WEEK")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        Spacer()

        Button {
          onViewTrends()
        } label: {
          Text("View month >")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      HStack(spacing: 0) {
        ForEach(weekDays, id: \.label) { day in
          VStack(spacing: 4) {
            Text(day.label)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(day.isToday ? theme.accent : theme.textTertiary)

            Text(day.number)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(day.isToday ? .white : theme.textPrimary)
              .frame(width: 36, height: 36)
              .background(day.isToday ? theme.accent : Color.clear)
              .clipShape(Circle())
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
  }

  private var statsGrid: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    return LazyVGrid(columns: columns, spacing: 12) {
      StatCard(
        icon: "clock",
        title: "Duration",
        value: durationString,
        theme: theme,
        iconColor: theme.accent
      )
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
        icon: "speaker.wave.2.fill",
        title: "Avg dB",
        value: String(format: "%.0f dB", session.averageDB),
        theme: theme,
        iconColor: theme.accent
      )
    }
  }

  private var chartSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Last 7 Nights")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        Spacer()

        Button {
          // See all
        } label: {
          Text("See all")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      let data = recentSessions.reversed().enumerated().map { index, session in
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let label = formatter.string(from: session.startDate).prefix(1).uppercased()
        return MiniBarChart.DataPoint(
          label: String(label),
          value: Double(session.sleepScore),
          color: theme.scoreColor(session.sleepScore)
        )
      }

      MiniBarChart(data: data, theme: theme)
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: session.startDate)
  }

  private var timeRangeString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    let start = formatter.string(from: session.startDate)
    if let endDate = session.endDate {
      let end = formatter.string(from: endDate)
      return "\(start) – \(end)"
    }
    return start
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    return String(format: "%d:%02d", hours, minutes)
  }

  private struct WeekDay: Identifiable {
    let id = UUID()
    let label: String
    let number: String
    let isToday: Bool
  }

  private var weekDays: [WeekDay] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let weekdaySymbols = calendar.shortWeekdaySymbols

    return (0..<7).map { offset in
      let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
      let isToday = calendar.isDate(date, inSameDayAs: today)
      let weekdayIndex = calendar.component(.weekday, from: date) - 1
      let label = weekdaySymbols[weekdayIndex].uppercased().prefix(3)
      let number = String(calendar.component(.day, from: date))
      return WeekDay(label: String(label), number: number, isToday: isToday)
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
        .foregroundStyle(theme.textTertiary)

      Text("Something went wrong")
        .font(.headline)
        .foregroundStyle(theme.textPrimary)

      Button("Try Again") {
        onRetry()
      }
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(theme.accent)
    }
  }
}
