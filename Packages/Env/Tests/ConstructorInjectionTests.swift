import EnvTestSupport
import Foundation
import Models
import Testing
@testable import Env

/// Services take their collaborators in `init` (defaulting to the container),
/// so their real logic runs against fakes and isolated stores.
@MainActor
struct ConstructorInjectionTests {
  // MARK: - TabCoordinator ← AppConfig

  private func config(hiding hidden: AppTab) -> AppConfig {
    let config = AppConfig.isolated()
    let tabs = AppTab.allCases.enumerated().map { TabConfig(tab: $1, isVisible: $1 != hidden, order: $0) }
    config.apply(flags: [:], tabs: tabs, learnTab: nil, updateGate: .none)
    return config
  }

  @Test func tabCoordinatorStartsOnTheFirstVisibleTab() {
    let coordinator = TabCoordinator(appConfig: config(hiding: .statistics))
    #expect(coordinator.selectedTab != .statistics)
  }

  @Test func deepLinkIsIgnoredWhenStatisticsIsHidden() {
    let coordinator = TabCoordinator(appConfig: config(hiding: .statistics))

    coordinator.open(.startTracking)

    #expect(coordinator.pendingDeepLink == nil)
  }

  @Test func deepLinkRoutesToStatisticsWhenVisible() {
    let coordinator = TabCoordinator(appConfig: AppConfig.isolated())
    coordinator.selectedTab = .settings

    coordinator.open(.last7Nights)

    #expect(coordinator.selectedTab == .statistics)
    #expect(coordinator.pendingDeepLink == .last7Nights)
  }

  // MARK: - SnoreInterrupterPlayer ← UserPreferences, haptics

  @Test func interrupterSetToNeverNeitherPlaysNorBuzzes() {
    let preferences = UserPreferences.isolated()
    preferences.snoreInterrupterMode = .never
    let haptics = FakeHapticManager()
    let player = SnoreInterrupterPlayer(preferences: preferences, melodyStorage: FakeCustomMelodyStorage(), haptics: haptics)

    player.playIfNeeded()

    #expect(!player.isPlaying)
    #expect(haptics.calls.isEmpty)
  }

  @Test func mutedInterrupterDoesNotPlay() {
    let preferences = UserPreferences.isolated()
    preferences.snoreInterrupterMode = .always
    let haptics = FakeHapticManager()
    let player = SnoreInterrupterPlayer(preferences: preferences, melodyStorage: FakeCustomMelodyStorage(), haptics: haptics)

    player.muteForSession()
    player.playIfNeeded()

    #expect(!player.isPlaying)
    #expect(haptics.calls.isEmpty)
  }
}
