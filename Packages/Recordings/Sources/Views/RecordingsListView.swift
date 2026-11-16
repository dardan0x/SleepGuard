import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SleepCore
import SwiftData
import SwiftUI

/// Every recorded night, by month and day (SleepCore's `NightMonth`), drawn by
/// the shared `NightsListContent` (ADR 0006). This container keeps the query,
/// navigation, and confirming and performing deletes.
@MainActor
public struct RecordingsListView: View {
  @Injected(\.theme) private var theme
  @Environment(\.modelContext) private var modelContext
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var viewState: ViewState = .loading
  @State private var dayToDelete: NightDay?

  public init() {}

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        Color.clear
          .task { loadState() }
      case .empty:
        NightsListEmptyContent()
      case let .loaded(months):
        NightsListContent(
          months: months,
          onOpen: { routerPath.navigate(to: .recordingDetail(id: $0.id)) },
          onDelete: { dayToDelete = $0 })
          .background(theme.bgPrimary)
          .alert(Strings.recordingsDetailRemoveTitle, isPresented: isConfirmingDelete, presenting: dayToDelete) { day in
            Button(Strings.actionRemove, role: .destructive) {
              delete(day)
            }
            Button(Strings.actionDiscard, role: .cancel) {}
          } message: { day in
            Text(String(format: Strings.recordingsDetailRemoveConfirmFormat, day.nights.count))
          }
          .refreshable {
            // SwiftData @Query auto-updates; refreshable provides UX feedback
          }
      case .error:
        RecordingsErrorView {
          loadState()
        }
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .onChange(of: sessions) { _, _ in
      loadState()
    }
  }

  private var isConfirmingDelete: Binding<Bool> {
    Binding(get: { dayToDelete != nil }, set: { if !$0 { dayToDelete = nil } })
  }

  /// Rows show each night's events, so the summaries read them (as the list
  /// always has).
  private func loadState() {
    if sessions.isEmpty {
      viewState = .empty
    } else {
      viewState = .loaded(months: NightMonth.months(from: sessions.map(\.nightSummary)))
    }
  }

  private func delete(_ day: NightDay) {
    let ids = Set(day.nights.map(\.id))
    let doomed = sessions.filter { ids.contains($0.id) }
    do {
      // Delete events first with intermediate save to avoid SwiftData faulting
      // crash during cascade delete on faulted relationship objects.
      for session in doomed {
        // Delete files while `session.events` still lists the event clips.
        deleteSessionFiles(session)
        if let events = session.events {
          for event in events {
            modelContext.delete(event)
          }
        }
      }
      try modelContext.save()

      for session in doomed {
        // Resolve transformable faults before deletion
        _ = session.sleepStageSegments
        _ = session.recordingGaps
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      // Deletion failed; UI will revert on next @Query update
    }
    dayToDelete = nil
  }

  public enum ViewState {
    case loading
    case empty
    case loaded(months: [NightMonth])
    case error
  }
}
