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
          .task {
            loadState()
          }
      case .empty:
        RecordingsEmptyView(theme: theme)
      case .loaded(let sections):
        RecordingsLoadedView(
          sections: sections,
          theme: theme
        )
      case .error:
        RecordingsErrorView(theme: theme) {
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
      let title = formatter.string(from: date)
      return MonthSection(
        id: title,
        title: title,
        sessions: sessions.sorted { $0.startDate > $1.startDate }
      )
    }
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
        .foregroundStyle(theme.secondaryLabelColor)

      Text("No recordings yet")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(theme.labelColor)

      Text("Your sleep sessions will appear here after you start recording.")
        .font(.system(size: 15))
        .foregroundStyle(theme.secondaryLabelColor)
        .multilineTextAlignment(.center)
    }
    .padding(32)
  }
}

// MARK: - Loaded State

@MainActor
struct RecordingsLoadedView: View {
  let sections: [MonthSection]
  let theme: Theme

  var body: some View {
    List {
      ForEach(sections) { section in
        Section {
          ForEach(section.sessions) { session in
            RecordingRowView(session: session, theme: theme)
          }
        } header: {
          Text(section.title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.secondaryLabelColor)
            .textCase(.uppercase)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(theme.backgroundColor)
    .refreshable {
      // SwiftData @Query auto-updates; refreshable provides UX feedback
    }
  }
}

// MARK: - Row View (minimal — extracted into full component in F4-T2)

@MainActor
struct RecordingRowView: View {
  let session: SleepSession
  let theme: Theme

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(dateString)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.labelColor)

        Text(durationString)
          .font(.system(size: 13))
          .foregroundStyle(theme.secondaryLabelColor)
      }

      Spacer()

      HStack(spacing: 4) {
        Text("\(session.sleepScore)")
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(scoreColor)

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.secondaryLabelColor)
      }
    }
    .padding(.vertical, 4)
    .listRowBackground(theme.surfaceColor)
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
