import ConfigTestSupport
import Foundation
import Models
import Testing
@testable import Config

/// Learn shows only when `feature_learn` says so, exactly once, at its order;
/// the tab list (defaults included) never adds it.
@MainActor
struct LearnTabOrderTests {
  private func config(tabs: [TabConfig] = [], learn: LearnTabConfig?) -> AppConfig {
    let config = AppConfig.isolated()
    config.apply(flags: [:], tabs: tabs, learnTab: learn, updateGate: .none)
    return config
  }

  @Test func defaultTabsLeaveLearnOutWhenItIsOff() {
    let tabs = config(learn: LearnTabConfig(isVisible: false, url: nil)).visibleTabsInOrder
    #expect(!tabs.contains(.learn))
    #expect(!tabs.isEmpty)
  }

  @Test func learnOnShowsItOnceAtItsOrder() {
    let tabs = config(learn: LearnTabConfig(isVisible: true, url: "https://example.com", order: 1)).visibleTabsInOrder
    #expect(tabs.filter { $0 == .learn }.count == 1)
    #expect(tabs.firstIndex(of: .learn) == 1)
  }

  @Test func aListThatHidesEverythingFallsBackWithoutLearn() {
    let hidden = AppTab.allCases.map { TabConfig(tab: $0, isVisible: false, order: 0) }
    let tabs = config(tabs: hidden, learn: nil).visibleTabsInOrder
    #expect(tabs == AppTab.allCases.filter { $0 != .learn })
  }

  @Test func aListThatShowsLearnStillDefersToItsConfig() {
    let list = AppTab.allCases.enumerated().map { TabConfig(tab: $1, isVisible: true, order: $0) }
    #expect(!config(tabs: list, learn: nil).visibleTabsInOrder.contains(.learn))
    let on = config(tabs: list, learn: LearnTabConfig(isVisible: true, url: nil, order: 9)).visibleTabsInOrder
    #expect(on.filter { $0 == .learn }.count == 1)
    #expect(on.last == .learn)
  }
}
