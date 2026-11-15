import FactoryKit

/// `AppTheme` lives in DesignSystem, above Env in the package graph, so its
/// registration lives here rather than in Env's `Container.swift`.
public extension Container {
  @MainActor var theme: Factory<any ThemeProviding> { self { AppTheme.shared }.singleton }
}
