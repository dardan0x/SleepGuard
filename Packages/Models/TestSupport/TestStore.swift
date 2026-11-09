import Foundation
import Models
import SwiftData

/// In-memory SwiftData store with the app's schema. Use it whenever a test
/// reads `events`, so relationships behave like production.
@MainActor
public final class TestStore {
  public let container: ModelContainer
  public var context: ModelContext {
    container.mainContext
  }

  public init() throws {
    let schema = Schema([SleepSession.self, SnoreEvent.self, UserProfile.self, LifestyleLog.self])
    container = try ModelContainer(
      for: schema,
      configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
  }

  /// Inserts the session, then attaches events and gaps. Order matters:
  /// SwiftData doesn't track changes made before insertion.
  @discardableResult
  public func insert(
    _ session: SleepSession,
    events: [SnoreEvent] = [],
    gaps: [RecordingGap] = []) throws -> SleepSession
  {
    context.insert(session)
    events.forEach { context.insert($0) }
    session.events = events
    session.recordingGaps = gaps
    try context.save()
    return session
  }
}
