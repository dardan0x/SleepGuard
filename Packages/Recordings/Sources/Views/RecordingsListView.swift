import SwiftUI
import SwiftData
import Env
import Models
import DesignSystem

@MainActor
public struct RecordingsListView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var viewState: ViewState = .loading
  @State private var showDeleteAlert = false
  @State private var groupToDelete: NightGroup?

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
            NightGroupRowView(
              group: group,
              theme: theme,
              onDeleteRequest: {
                groupToDelete = group
                showDeleteAlert = true
              }
            )
            .padding(.vertical, 8)
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                groupToDelete = group
                showDeleteAlert = true
              } label: {
                Label(Strings.actionDelete, systemImage: "trash")
              }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
    .alert(Strings.recordingsDetailRemoveTitle, isPresented: $showDeleteAlert, presenting: groupToDelete) { group in
      Button(Strings.actionRemove, role: .destructive) {
        deleteGroup(group)
      }
      Button(Strings.actionDiscard, role: .cancel) {}
    } message: { group in
      Text(String(format: Strings.recordingsDetailRemoveConfirmFormat, group.recordingCount))
    }
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
    SessionGrouper.groupSessions(sessions)
  }

  private func deleteGroup(_ group: NightGroup) {
    for session in group.sessions {
      deleteSessionFiles(session)
      modelContext.delete(session)
    }
    do {
      try modelContext.save()
    } catch {
      // Deletion failed; UI will revert on next @Query update
    }
    groupToDelete = nil
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(sections: [MonthSection])
    case error
  }
}
