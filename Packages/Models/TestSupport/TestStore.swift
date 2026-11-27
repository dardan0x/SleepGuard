import Foundation
public import Models
public import SleepCore
public import SwiftData
public import SleepStore

/// In-memory SwiftData store with the shared versioned schema and migration plan (SleepStore). Use it whenever a test
/// reads `events`, so relationships behave like production.
@MainActor
public final class TestStore {
  public let container: ModelContainer
  public var context: ModelContext {
    container.mainContext
  }

  public init() throws {
    container = try SleepStoreSchema.container(at: nil)
  }

  /// Inserts the session, then attaches events and gaps. Order matters:
  /// SwiftData doesn't track changes made before insertion.
  @discardableResult
  public func insert(
    _ session: NightRecord,
    events: [NightEventRecord] = [],
    gaps: [RecordingGap] = []) throws -> NightRecord
  {
    context.insert(session)
    events.forEach { context.insert($0) }
    session.events = events
    session.recordingGaps = gaps
    try context.save()
    return session
  }
}
