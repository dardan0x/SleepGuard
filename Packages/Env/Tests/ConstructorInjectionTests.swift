import Config
import ConfigTestSupport
import EnvTestSupport
import Foundation
import Models
import PlatformTestSupport
import Testing
@testable import Env

/// Services take their collaborators in `init` (defaulting to the container),
/// so their real logic runs against fakes and isolated stores.
@MainActor
struct ConstructorInjectionTests {
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
