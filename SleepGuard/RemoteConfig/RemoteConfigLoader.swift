import Foundation
import FirebaseRemoteConfig
import Env
import Models

/// Bridges Firebase Remote Config into the Firebase-free `AppConfig` store.
/// This is the only place that imports Firebase Remote Config, keeping the
/// dependency out of every feature package.
@MainActor
final class RemoteConfigLoader {
  static let shared = RemoteConfigLoader()

  private let remoteConfig: RemoteConfig

  private enum Key {
    static let featureFlags = "feature_flags"
    static let tabs = "tabs"
    static let featureLearn = "feature_learn"
    static let minimumVersion = "minimum_version"
    static let recommendedVersion = "recommended_version"
  }

  private init() {
    remoteConfig = RemoteConfig.remoteConfig()

    let settings = RemoteConfigSettings()
    #if DEBUG
    settings.minimumFetchInterval = 0
    #else
    settings.minimumFetchInterval = 3600
    #endif
    remoteConfig.configSettings = settings

    remoteConfig.setDefaults([
      Key.featureFlags: Self.defaultFlagsJSON() as NSObject,
      Key.tabs: Self.defaultTabsJSON() as NSObject,
      Key.featureLearn: Self.defaultLearnTabJSON() as NSObject,
      Key.minimumVersion: UpdateGate.none.minimumVersion as NSObject,
      Key.recommendedVersion: UpdateGate.none.recommendedVersion as NSObject,
    ])
  }

  /// Fetches the latest values and pushes them into `AppConfig`. On failure,
  /// applies whatever is already activated (last fetch or baked-in defaults).
  func refresh() async {
    do {
      try await remoteConfig.fetchAndActivate()
    } catch {
      print("[RemoteConfigLoader] fetch failed: \(error)")
    }
    apply()
  }

  private func apply() {
    let flags = Self.decodeFlags(remoteConfig[Key.featureFlags].stringValue)
    let tabs = Self.decodeTabs(remoteConfig[Key.tabs].stringValue)
    let learnTab = Self.decodeLearnTab(remoteConfig[Key.featureLearn].stringValue)
    let gate = UpdateGate(
      minimumVersion: remoteConfig[Key.minimumVersion].stringValue,
      recommendedVersion: remoteConfig[Key.recommendedVersion].stringValue
    )
    AppConfig.shared.apply(flags: flags, tabs: tabs, learnTab: learnTab, updateGate: gate)
  }

  // MARK: - Decoding

  private static func decodeFlags(_ json: String) -> [String: Bool] {
    guard let data = json.data(using: .utf8),
          let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
      return [:]
    }
    return dict
  }

  private static func decodeTabs(_ json: String) -> [TabConfig] {
    guard let data = json.data(using: .utf8),
          let tabs = try? JSONDecoder().decode([TabConfig].self, from: data) else {
      return []
    }
    return tabs
  }

  private static func decodeLearnTab(_ json: String) -> LearnTabConfig? {
    guard let data = json.data(using: .utf8) else { return nil }

    if let config = try? JSONDecoder().decode(LearnTabConfig.self, from: data) {
      return config
    }

    if let isVisible = try? JSONDecoder().decode(Bool.self, from: data) {
      return LearnTabConfig(isVisible: isVisible, url: nil)
    }

    return nil
  }

  // MARK: - Defaults (mirror the baked-in AppConfig defaults)

  private static func defaultFlagsJSON() -> String {
    let dict = Dictionary(uniqueKeysWithValues: FeatureFlag.allCases.map { ($0.rawValue, $0.defaultValue) })
    guard let data = try? JSONEncoder().encode(dict),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }

  private static func defaultTabsJSON() -> String {
    guard let data = try? JSONEncoder().encode(TabConfig.defaults),
          let json = String(data: data, encoding: .utf8) else { return "[]" }
    return json
  }

  private static func defaultLearnTabJSON() -> String {
    let config = LearnTabConfig(isVisible: false, url: nil)
    guard let data = try? JSONEncoder().encode(config),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }
}
