import Foundation
import Models
import Observation
import SleepCore

/// Remote-driven feature flags, tabs, update gate, and score config.
/// Live: `AppConfig`. Tests: `AppConfig(defaults:)` on an isolated suite.
@MainActor
public protocol AppConfigProviding: AnyObject, Observable {
  var tabs: [TabConfig] { get }
  var updateGate: UpdateGate { get }
  var sleepScoreConfig: SleepScoreConfig { get }
  var learnTabConfig: LearnTabConfig? { get }
  var visibleTabsInOrder: [AppTab] { get }
  func isEnabled(_ flag: FeatureFlag) -> Bool
  func apply(flags: [String: Bool], tabs: [TabConfig], learnTab: LearnTabConfig?, updateGate: UpdateGate)
  #if DEBUG
  var effectiveTabs: [TabConfig] { get }
  var effectiveLearnTab: LearnTabConfig { get }
  func overrideValue(for flag: FeatureFlag) -> Bool
  func setOverride(_ flag: FeatureFlag, _ value: Bool)
  func setTabOverrides(_ configs: [TabConfig])
  func setLearnTabOverride(_ config: LearnTabConfig?)
  func setUpdateGateOverride(_ gate: UpdateGate?)
  func setSleepScoreConfigOverride(_ config: SleepScoreConfig?)
  func clearOverrides()
  #endif
}
