import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SleepCore
import SwiftData
import SwiftUI

/// A month of nights. Hosts the shared `CalendarContent` (ADR 0006) under
/// SleepGuard's toolbar (title capsule, Today).
@MainActor
public struct CalendarView: View {
  @Injected(\.theme) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Query(sort: \SleepSession.startDate, order: .reverse)
  private var sessions: [SleepSession]

  @State private var selectedMonth = Date()
  @State private var selectedDay = Calendar.current.startOfDay(for: Date())

  private let calendar = Calendar.current

  public init() {}

  public var body: some View {
    ScrollView {
      CalendarContent(month: $selectedMonth, selectedDay: $selectedDay, nights: gridNights) { night in
        routerPath.navigate(to: .sessionDetail(id: night.id))
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack(spacing: 6) {
          Image(systemName: "calendar")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
          Text(Strings.watchCalendar)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(theme.surface2)
        )
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = Date()
            selectedDay = calendar.startOfDay(for: Date())
          }
        } label: {
          Text(Strings.statsMiniChartToday)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }
    }
  }

  /// Full summaries of the nights in the month's grid (42 days), for their
  /// loudest snoring. Chosen without reading events.
  private var gridNights: [NightSummary] {
    let grid = CalendarMonth.grid(for: selectedMonth, calendar: calendar)
    guard let first = grid.first, let last = grid.last,
          let end = calendar.date(byAdding: .day, value: 1, to: last) else { return [] }
    let chosen = sessions.summariesWithoutEvents.filter { $0.start >= first && $0.start < end }
    return sessions.fullSummaries(of: chosen)
  }
}
