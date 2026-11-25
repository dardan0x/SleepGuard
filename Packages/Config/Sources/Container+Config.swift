import FactoryKit

/// Config's registrations. Tests use `AppConfig.isolated()` /
/// `UserPreferences.isolated()` (ConfigTestSupport): the real types on a
/// throwaway `UserDefaults` suite.
public extension Container {
  @MainActor var appConfig: Factory<any AppConfigProviding> { self { AppConfig.shared }.singleton }
  @MainActor var userPreferences: Factory<any UserPreferencesStoring> { self { UserPreferences.shared }.singleton }
}
