import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct LastNightEntry: TimelineEntry {
  let date: Date
  let night: WidgetSnapshot.Night?
}

/// Reads the snapshot the app writes to the App Group. The app reloads
/// timelines whenever it rewrites the snapshot, so the policy is `.never`.
struct LastNightProvider: TimelineProvider {
  func placeholder(in _: Context) -> LastNightEntry {
    LastNightEntry(date: .now, night: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (LastNightEntry) -> Void) {
    let entry = currentEntry()
    // Widget gallery shows sample data until the user has a night recorded.
    completion(context.isPreview && entry.night == nil ? placeholder(in: context) : entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<LastNightEntry>) -> Void) {
    completion(Timeline(entries: [currentEntry()], policy: .never))
  }

  private func currentEntry() -> LastNightEntry {
    let snapshot = WidgetSnapshotStore.fileURL.flatMap(WidgetSnapshotStore.read(from:))
    return LastNightEntry(date: .now, night: snapshot?.lastNight)
  }
}

struct LastNightWidget: Widget {
  let kind = "LastNightWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LastNightProvider()) { entry in
      LastNightWidgetView(entry: entry)
    }
    .configurationDisplayName(Strings.widgetLastNightName)
    .description(Strings.widgetLastNightDescription)
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

extension WidgetSnapshot.Night {
  static let sample = WidgetSnapshot.Night(
    id: UUID(),
    startDate: .now.addingTimeInterval(-8 * 3600),
    endDate: .now.addingTimeInterval(-1 * 3600),
    score: 82,
    snoringDuration: 42 * 60)
}

#Preview(as: .systemSmall) {
  LastNightWidget()
} timeline: {
  LastNightEntry(date: .now, night: .sample)
  LastNightEntry(date: .now, night: nil)
}

#Preview(as: .systemMedium) {
  LastNightWidget()
} timeline: {
  LastNightEntry(date: .now, night: .sample)
  LastNightEntry(date: .now, night: nil)
}
