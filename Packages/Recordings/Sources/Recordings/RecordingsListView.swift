import SwiftUI
import SwiftData
import Env
import Models
import DesignSystem

@MainActor
public struct RecordingsListView: View {
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
        RecordingsEmptyView(theme: theme)
      case .loaded(let sections):
        loadedBody(sections: sections)
      case .error:
        RecordingsErrorView(theme: theme) {
          loadState()
        }
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
    .onChange(of: sessions) { _, _ in
      loadState()
    }
  }

  private func loadedBody(sections: [MonthSection]) -> some View {
    List {
      ForEach(sections) { section in
        Section {
          ForEach(section.sessions) { session in
            let color = intensityColor(for: session)
            SessionRow(
              dayNumber: dayString(from: session.startDate),
              weekday: weekdayString(from: session.startDate),
              duration: durationString(session.totalDuration),
              events: "\(session.eventsCount) events",
              intensityColor: color,
              theme: theme
            )
            .contentShape(Rectangle())
            .onTapGesture {
              routerPath.navigate(to: .sessionDetail(id: session.id))
            }
          }
        } header: {
          Text(section.title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.textTertiary)
            .textCase(.uppercase)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(theme.bgSecondary)
    .refreshable {
      // SwiftData @Query auto-updates; refreshable provides UX feedback
    }
  }

  private func loadState() {
    if sessions.isEmpty {
      viewState = .empty
    } else {
      viewState = .loaded(sections: groupSessions(sessions))
    }
  }

  private func groupSessions(_ sessions: [SleepSession]) -> [MonthSection] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: sessions) { session in
      calendar.dateComponents([.year, .month], from: session.startDate)
    }

    let sorted = grouped.sorted { a, b in
      if a.key.year != b.key.year {
        return a.key.year! > b.key.year!
      }
      return a.key.month! > b.key.month!
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"

    return sorted.map { components, sessions in
      let date = calendar.date(from: components)!
      let title = formatter.string(from: date).uppercased()
      return MonthSection(
        id: title,
        title: title,
        sessions: sessions.sorted { $0.startDate > $1.startDate }
      )
    }
  }

  private func dayString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd"
    return formatter.string(from: date)
  }

  private func weekdayString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date).uppercased()
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return String(format: "%dh %02dm", hours, minutes)
  }

  private func intensityColor(for session: SleepSession) -> Color {
    guard let events = session.events, !events.isEmpty else {
      return theme.snoreQuiet
    }
    let loud = events.filter { $0.intensity == .loud }.count
    let light = events.filter { $0.intensity == .light }.count
    if loud >= light {
      return theme.snoreLoud
    }
    if light > 0 {
      return theme.snoreLight
    }
    return theme.snoreQuiet
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(sections: [MonthSection])
    case error
  }
}

// MARK: - Month Section

public struct MonthSection: Identifiable {
  public let id: String
  public let title: String
  public let sessions: [SleepSession]
}

// MARK: - Empty State

@MainActor
struct RecordingsEmptyView: View {
  let theme: Theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text("No recordings yet")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Text("Your sleep sessions will appear here after you start recording.")
        .font(.system(size: 15))
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(32)
  }
}

// MARK: - Error State

@MainActor
struct RecordingsErrorView: View {
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
