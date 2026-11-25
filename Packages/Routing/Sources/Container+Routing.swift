import FactoryKit

/// Routing's registration: app-wide tab state. `RouterPath` is not registered:
/// it is per-tab SwiftUI environment state (docs/adr/0001-routing-package.md).
public extension Container {
  @MainActor var tabCoordinator: Factory<any TabCoordinating> { self { TabCoordinator.shared }.singleton }
}
