import Env
import Foundation

public extension UserDefaults {
  /// A fresh, empty suite for one test or preview. Nothing leaks into
  /// `.standard` or into other tests.
  static func isolated() -> UserDefaults {
    let name = "EnvTestSupport.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
  }
}

/// `UserPreferences` and `AppConfig` are `UserDefaults`-backed value stores:
/// their test double is the real type on an isolated suite, so every
/// property behaves exactly like production.
@MainActor
public extension UserPreferences {
  static func isolated() -> UserPreferences {
    UserPreferences(defaults: .isolated())
  }
}

@MainActor
public extension AppConfig {
  static func isolated() -> AppConfig {
    AppConfig(defaults: .isolated())
  }
}
