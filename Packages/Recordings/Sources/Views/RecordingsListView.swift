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
          ForEach(section.groups) { group in
            NightGroupRowView(group: group, theme: theme)
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

    // Group by month
    let monthGrouped = Dictionary(grouping: sessions) { session in
      calendar.dateComponents([.year, .month], from: session.startDate)
    }

    let sortedMonths = monthGrouped.sorted { a, b in
      if a.key.year != b.key.year {
        return a.key.year! > b.key.year!
      }
      return a.key.month! > b.key.month!
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"

    return sortedMonths.map { components, monthSessions in
      let monthDate = calendar.date(from: components)!
      let title = formatter.string(from: monthDate).uppercased()

      // Within each month, group by day
      let dayGrouped = Dictionary(grouping: monthSessions) { session in
        calendar.startOfDay(for: session.startDate)
      }

      let groups = dayGrouped.map { dayDate, daySessions in
        NightGroup(
          id: ISO8601DateFormatter.string(from: dayDate, timeZone: calendar.timeZone, formatOptions: [.withFullDate]),
          date: dayDate,
          sessions: daySessions.sorted { $0.startDate > $1.startDate }
        )
      }.sorted { $0.date > $1.date }

      return MonthSection(
        id: title,
        title: title,
        groups: groups
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
