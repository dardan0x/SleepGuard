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
            RecordingRowView(session: session, theme: theme)
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

  public enum ViewState {
    case loading
    case empty
    case loaded(sections: [MonthSection])
    case error
  }
}
