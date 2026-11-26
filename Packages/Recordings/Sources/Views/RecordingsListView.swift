import DesignSystem
import Models
import os
import Routing
import Services
public import SleepCore
import SwiftData
public import SwiftUI

/// Every recorded night, by month and day (SleepCore's `NightMonth`), drawn by
/// the shared `NightsListContent` (ADR 0006). This container keeps the query,
/// navigation, and confirming and performing deletes.
@MainActor
public struct RecordingsListView: View {
  @Environment(\.theme) private var theme
  @Environment(\.modelContext) private var modelContext
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \NightRecord.start, order: .reverse)
  private var sessions: [NightRecord]

  @State private var viewState: ViewState = .loading
  @State private var dayToDelete: NightDay?
  @State private var deleteFailed = false

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
          .background(theme.palette.bgPrimary)
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
      }
    }
    .alert(Strings.sessionDeleteFailedTitle, isPresented: $deleteFailed) {
      Button(Strings.actionOk, role: .cancel) {}
    } message: {
      Text(Strings.sessionDeleteFailedMessage)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
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
      viewState = .loaded(months: NightMonth.months(from: sessions.map(\.summary)))
    }
  }

  /// Deletes the day's nights: rows first, then (once saved) their audio
  /// files, so a failure leaves orphan files (cleaned by storage limits), never
  /// a night without its clips. A failure is reported, not swallowed.
  private func delete(_ day: NightDay) {
    let ids = Set(day.nights.map(\.id))
    let doomed = sessions.filter { ids.contains($0.id) }
    let files = doomed.flatMap(sessionFileURLs)
    do {
      // Events first with an intermediate save: deleting a faulted
      // relationship in one cascade has crashed SwiftData.
      for session in doomed {
        for event in session.events {
          modelContext.delete(event)
        }
      }
      try modelContext.save()

      for session in doomed {
        // Resolve transformable faults before deletion
        _ = session.sleepStages
        _ = session.recordingGaps
        modelContext.delete(session)
      }
      try modelContext.save()
      removeFiles(files)
    } catch {
      modelContext.rollback()
      Log.storage.error("Deleting a day's nights failed: \(String(describing: error), privacy: .public)")
      deleteFailed = true
    }
    dayToDelete = nil
  }

  /// No `.error`: `@Query` doesn't surface fetch errors, so it could never be reached.
  public enum ViewState {
    case loading
    case empty
    case loaded(months: [NightMonth])
  }
}
