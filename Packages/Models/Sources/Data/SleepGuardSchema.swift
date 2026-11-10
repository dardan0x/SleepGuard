import Foundation
import SwiftData

/// The SwiftData schema as shipped before F22. The app and `TestStore` both open
/// their `ModelContainer` through `SleepGuardSchema.container(...)`, so
/// production and tests can never drift onto different schemas.
///
/// V1 points at the live `@Model` classes. That is correct only while V1 is the
/// latest version. Before the first breaking change (see "Adding V2" in
/// CLAUDE.md), freeze V1 by copying today's classes into this enum as nested
/// types, then declare `SleepGuardSchemaV2` with the live classes.
public enum SleepGuardSchemaV1: VersionedSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)

  public static var models: [any PersistentModel.Type] {
    [SleepSession.self, SnoreEvent.self, UserProfile.self, LifestyleLog.self]
  }
}

/// Ordered schema history. Empty `stages` until V2 exists: additive changes
/// still go through SwiftData's automatic lightweight migration.
public enum SleepGuardMigrationPlan: SchemaMigrationPlan {
  public static var schemas: [any VersionedSchema.Type] {
    [SleepGuardSchemaV1.self]
  }

  public static var stages: [MigrationStage] {
    []
  }
}

public enum SleepGuardSchema {
  /// The latest schema version. Update this when adding a version.
  public typealias Current = SleepGuardSchemaV1

  public static var schema: Schema {
    Schema(versionedSchema: Current.self)
  }

  public static func configuration(inMemory: Bool) -> ModelConfiguration {
    ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
  }

  /// Opens a container for `configuration` with the migration plan attached.
  public static func container(_ configuration: ModelConfiguration) throws -> ModelContainer {
    try ModelContainer(
      for: schema,
      migrationPlan: SleepGuardMigrationPlan.self,
      configurations: [configuration])
  }
}
