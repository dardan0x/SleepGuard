import Foundation
import Models
import Observation

/// Firebase-free configuration store. Holds remotely-driven feature flags, tab
/// configuration, and update-gate thresholds as plain Swift values so every
/// feature package can read them without linking Firebase.
///
/// A thin `RemoteConfigLoader` in the app target fetches from Firebase Remote
/// Config and pushes values in via `apply(...)`. Until that happens (offline,
/// first launch, or no Firebase project), reads fall back to the last good
/// cached fetch and then to baked-in defaults.
///
/// Resolution order for every value: debug override → remote/cache → default.
@MainActor
@Observable
public final class AppConfig: AppConfigProviding {
  public static let shared = AppConfig()

  private let defaults: UserDefaults

  private enum Key {
    static let flags = "appconfig.flags"
    static let tabs = "appconfig.tabs"
    static let updateGate = "appconfig.updateGate"
    static let learnTab = "appconfig.learnTab"
    static let debugFlags = "appconfig.debug.flags"
    static let debugTabs = "appconfig.debug.tabs"
    static let debugLearnTab = "appconfig.debug.learnTab"
    static let debugSleepScoreConfig = "appconfig.debug.sleepScoreConfig"
  }

  /// Last applied/cached remote values (raw, keyed by `FeatureFlag.rawValue`).
  private var remoteFlags: [String: Bool] = [:]
  public private(set) var tabs: [TabConfig] = TabConfig.defaults
  private var remoteLearnTab: LearnTabConfig?
  private var remoteUpdateGate: UpdateGate = .none

  /// Update gate in effect, applying the debug override first.
  public var updateGate: UpdateGate {
    #if DEBUG
    if let debugUpdateGate { return debugUpdateGate }
    #endif
    return remoteUpdateGate
  }

  /// Resolved sleep score configuration.
  /// In DEBUG builds a local override can be set for testing; release builds always
  /// use the baked-in `SleepScoreConfig.default`.
  public var sleepScoreConfig: SleepScoreConfig {
    #if DEBUG
    if let debugSleepScoreConfig { return debugSleepScoreConfig }
    #endif
    return .default
  }

  #if DEBUG
  /// Local-only overrides set from the debug panel. Consulted before remote/cache.
  private var debugFlags: [String: Bool] = [:]
  private var debugTabs: [TabConfig]?
  private var debugLearnTab: LearnTabConfig?
  private var debugUpdateGate: UpdateGate?
  private var debugSleepScoreConfig: SleepScoreConfig?
  #endif

  /// `defaults` is `.standard` in the app; tests pass an isolated suite.
  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    loadCache()
  }

  // MARK: - Reads

  /// Whether a feature is on, applying the full resolution order.
  public func isEnabled(_ flag: FeatureFlag) -> Bool {
    #if DEBUG
    if let override = debugFlags[flag.rawValue] { return override }
    #endif
    if let remote = remoteFlags[flag.rawValue] { return remote }
    return flag.defaultValue
  }

  /// Resolved Learn tab configuration, applying debug overrides first.
  public var learnTabConfig: LearnTabConfig? {
    #if DEBUG
    return debugLearnTab ?? remoteLearnTab
    #else
    return remoteLearnTab
    #endif
  }

  /// Visible tabs in display order. Falls back to all tabs in canonical order
  /// if the resolved configuration is empty or hides everything.
  public var visibleTabsInOrder: [AppTab] {
    let source: [TabConfig]
    #if DEBUG
    source = debugTabs ?? tabs
    #else
    source = tabs
    #endif
    var visible = source.filter(\.isVisible).sorted { $0.order < $1.order }.map(\.tab)

    if let learnConfig = learnTabConfig, learnConfig.isVisible {
      let insertIndex = min(max(learnConfig.order, 0), visible.count)
      visible.insert(.learn, at: insertIndex)
    }

    return visible.isEmpty ? AppTab.allCases : visible
  }

  // MARK: - Apply (called by RemoteConfigLoader)

  /// Applies a fresh set of remote values and persists them as the cache.
  public func apply(
    flags: [String: Bool],
    tabs: [TabConfig],
    learnTab: LearnTabConfig?,
    updateGate: UpdateGate)
  {
    remoteFlags = flags
    self.tabs = tabs.isEmpty ? TabConfig.defaults : tabs
    remoteLearnTab = learnTab
    remoteUpdateGate = updateGate
    persistCache()
  }

  // MARK: - Debug overrides

  #if DEBUG
  /// Effective flag value as shown in the debug panel (override if set, else resolved).
  public func overrideValue(for flag: FeatureFlag) -> Bool {
    debugFlags[flag.rawValue] ?? isEnabled(flag)
  }

  public func setOverride(_ flag: FeatureFlag, _ value: Bool) {
    debugFlags[flag.rawValue] = value
    defaults.set(debugFlags, forKey: Key.debugFlags)
  }

  /// Current effective tab configuration for editing in the debug panel.
  public var effectiveTabs: [TabConfig] {
    (debugTabs ?? tabs).sorted { $0.order < $1.order }
  }

  public func setTabOverrides(_ configs: [TabConfig]) {
    debugTabs = configs
    persistDebugTabs(configs)
  }

  /// Current effective Learn tab configuration for editing in the debug panel.
  public var effectiveLearnTab: LearnTabConfig {
    debugLearnTab ?? learnTabConfig ?? LearnTabConfig(isVisible: false, url: nil)
  }

  public func setLearnTabOverride(_ config: LearnTabConfig?) {
    debugLearnTab = config
    if let config {
      if let data = try? JSONEncoder().encode(config) {
        defaults.set(data, forKey: Key.debugLearnTab)
      }
    } else {
      defaults.removeObject(forKey: Key.debugLearnTab)
    }
  }

  /// Forces a specific update gate locally (for testing soft/hard prompts).
  public func setUpdateGateOverride(_ gate: UpdateGate?) {
    debugUpdateGate = gate
  }

  /// Forces a specific sleep score config locally (for testing scoring changes).
  public func setSleepScoreConfigOverride(_ config: SleepScoreConfig?) {
    debugSleepScoreConfig = config
    if let config {
      if let data = try? JSONEncoder().encode(config) {
        defaults.set(data, forKey: Key.debugSleepScoreConfig)
      }
    } else {
      defaults.removeObject(forKey: Key.debugSleepScoreConfig)
    }
  }

  public func clearOverrides() {
    debugFlags = [:]
    debugTabs = nil
    debugLearnTab = nil
    debugUpdateGate = nil
    debugSleepScoreConfig = nil
    defaults.removeObject(forKey: Key.debugFlags)
    defaults.removeObject(forKey: Key.debugTabs)
    defaults.removeObject(forKey: Key.debugLearnTab)
    defaults.removeObject(forKey: Key.debugSleepScoreConfig)
  }
  #endif

  // MARK: - Cache persistence

  private func persistCache() {
    defaults.set(remoteFlags, forKey: Key.flags)
    if let data = try? JSONEncoder().encode(tabs) {
      defaults.set(data, forKey: Key.tabs)
    }
    if let data = try? JSONEncoder().encode(remoteLearnTab) {
      defaults.set(data, forKey: Key.learnTab)
    }
    if let data = try? JSONEncoder().encode(remoteUpdateGate) {
      defaults.set(data, forKey: Key.updateGate)
    }
  }

  private func loadCache() {
    if let cached = defaults.dictionary(forKey: Key.flags) as? [String: Bool] {
      remoteFlags = cached
    }
    if let data = defaults.data(forKey: Key.tabs),
       let decoded = try? JSONDecoder().decode([TabConfig].self, from: data),
       !decoded.isEmpty
    {
      tabs = decoded
    }
    if let data = defaults.data(forKey: Key.learnTab),
       let decoded = try? JSONDecoder().decode(LearnTabConfig.self, from: data)
    {
      remoteLearnTab = decoded
    }
    if let data = defaults.data(forKey: Key.updateGate),
       let decoded = try? JSONDecoder().decode(UpdateGate.self, from: data)
    {
      remoteUpdateGate = decoded
    }
    #if DEBUG
    if let cached = defaults.dictionary(forKey: Key.debugFlags) as? [String: Bool] {
      debugFlags = cached
    }
    if let data = defaults.data(forKey: Key.debugTabs),
       let decoded = try? JSONDecoder().decode([TabConfig].self, from: data)
    {
      debugTabs = decoded
    }
    if let data = defaults.data(forKey: Key.debugLearnTab),
       let decoded = try? JSONDecoder().decode(LearnTabConfig.self, from: data)
    {
      debugLearnTab = decoded
    }
    if let data = defaults.data(forKey: Key.debugSleepScoreConfig),
       let decoded = try? JSONDecoder().decode(SleepScoreConfig.self, from: data)
    {
      debugSleepScoreConfig = decoded
    }
    #endif
  }

  #if DEBUG
  private func persistDebugTabs(_ configs: [TabConfig]) {
    if let data = try? JSONEncoder().encode(configs) {
      defaults.set(data, forKey: Key.debugTabs)
    }
  }
  #endif
}
