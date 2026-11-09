import Models
import WidgetKit

struct SnapshotEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

/// Shared by every SleepGuard widget: reads the snapshot the app writes to the
/// App Group. The app reloads timelines whenever it rewrites the snapshot, so
/// the policy is `.never`.
struct WidgetSnapshotProvider: TimelineProvider {
  func placeholder(in _: Context) -> SnapshotEntry {
    SnapshotEntry(date: .now, snapshot: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
    let entry = currentEntry()
    // Widget gallery shows sample data until the user has a night recorded.
    completion(context.isPreview && entry.snapshot.lastNight == nil ? placeholder(in: context) : entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
    completion(Timeline(entries: [currentEntry()], policy: .never))
  }

  private func currentEntry() -> SnapshotEntry {
    let snapshot = WidgetSnapshotStore.fileURL.flatMap(WidgetSnapshotStore.read(from:)) ?? .empty
    return SnapshotEntry(date: .now, snapshot: snapshot)
  }
}

extension WidgetSnapshot {
  static let empty = WidgetSnapshot(generatedAt: .now, lastNight: nil, recentDays: [])

  static let sample = WidgetSnapshot(
    generatedAt: .now,
    lastNight: WidgetSnapshot.Night(
      id: UUID(),
      startDate: .now.addingTimeInterval(-8 * 3600),
      endDate: .now.addingTimeInterval(-1 * 3600),
      score: 82,
      snoringDuration: 42 * 60),
    recentDays: [72, 80, 65, 88, 76, 84, 82].enumerated().map { index, score in
      Day(date: Calendar.current.date(byAdding: .day, value: index - 6, to: .now) ?? .now, averageScore: score)
    })
}
