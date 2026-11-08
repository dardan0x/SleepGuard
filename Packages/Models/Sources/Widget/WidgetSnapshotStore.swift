import Foundation

/// Reads and writes `WidgetSnapshot` as JSON in the shared App Group container.
public enum WidgetSnapshotStore {
  public static let appGroupID = "group.com.dardan.SleepGuard"

  /// `nil` when the App Group entitlement is missing.
  public static var fileURL: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
      .appendingPathComponent("widget-snapshot.json")
  }

  public static func write(_ snapshot: WidgetSnapshot, to url: URL) throws {
    try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
  }

  public static func read(from url: URL) -> WidgetSnapshot? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
  }
}
