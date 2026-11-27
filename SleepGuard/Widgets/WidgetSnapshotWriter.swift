import Models
import os
import SleepLogging
import SleepStore
import SwiftData
import WidgetKit

/// Writes the widget snapshot to the App Group and reloads widget timelines.
/// Called at launch and when the app goes to the background — widgets are never
/// visible while the app is foregrounded, so this covers every save/delete path.
enum WidgetSnapshotWriter {
  /// Enough sessions to cover the 7 most recent days with sessions.
  private static let fetchLimit = 50

  static func update(modelContext: ModelContext) {
    guard let url = WidgetSnapshotStore.fileURL else { return }

    var descriptor = FetchDescriptor<NightRecord>(
      predicate: #Predicate { $0.scoreVersion != "" },
      sortBy: [SortDescriptor(\.start, order: .reverse)])
    descriptor.fetchLimit = fetchLimit

    do {
      let sessions = try modelContext.fetch(descriptor)
      try WidgetSnapshotStore.write(WidgetSnapshotBuilder.make(from: sessions), to: url)
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      Log.app.error("Failed to update widget snapshot: \(String(describing: error), privacy: .public)")
    }
  }
}
