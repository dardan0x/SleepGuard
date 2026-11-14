import Foundation
import Models
import SleepCore

extension [SleepSession] {
  /// Every night without reading events: enough to choose nights.
  var summariesWithoutEvents: [NightSummary] {
    map(\.summaryWithoutEvents)
  }

  /// Full summaries (events read) of only the given nights, in their order.
  func fullSummaries(of nights: [NightSummary]) -> [NightSummary] {
    let byID = Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    return nights.compactMap { byID[$0.id]?.nightSummary }
  }
}
