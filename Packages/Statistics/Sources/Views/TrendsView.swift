import DesignSystem
import Models
import SleepCore
import SwiftData
public import SwiftUI

/// Trends: the week's or month's nights. Hosts the shared `TrendsContent`
/// (ADR 0006) under SleepGuard's toolbar title.
@MainActor
public struct TrendsView: View {
  @Environment(\.theme) private var theme
  @Query(sort: \NightRecord.start, order: .reverse)
  private var sessions: [NightRecord]

  @State private var range = TrendsRange.week

  public init() {}

  public var body: some View {
    ScrollView {
      TrendsContent(range: $range, period: period)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(Strings.statsTrendsTitle)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
      }
    }
  }

  /// The week's or month's nights, from SleepCore's `NightPeriod`. Chosen
  /// without reading events, then built in full for those nights only.
  private var period: NightPeriod {
    let now = Date()
    let chosen = NightPeriod(lastDays: range.days, of: sessions.summariesWithoutEvents, now: now).nights
    return NightPeriod(lastDays: range.days, of: sessions.fullSummaries(of: chosen), now: now)
  }
}
