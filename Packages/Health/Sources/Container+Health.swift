import FactoryKit

/// Health's registration. Fake: `FakeHealthKitSync` (HealthTestSupport).
public extension Container {
  @MainActor var healthKitSync: Factory<any HealthKitSyncing> { self { HealthKitSync.shared }.singleton }
}
