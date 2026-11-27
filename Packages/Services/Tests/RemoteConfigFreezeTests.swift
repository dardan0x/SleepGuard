import Config
import ConfigTestSupport
import Foundation
import Models
import PlatformTestSupport
import ServicesTestSupport
import Testing
@testable import Services

/// A recorded night runs under one set of remote values: a flag that changes
/// mid-night waits until the stop (principal review Q50).
@MainActor
struct RemoteConfigFreezeTests {
  private func flags(interrupter: Bool) -> [String: Bool] {
    [FeatureFlag.snoreInterrupter.rawValue: interrupter]
  }

  @Test func remoteValuesWaitWhileHeldAndApplyOnRelease() {
    let config = AppConfig.isolated()
    config.holdRemoteUpdates()

    config.apply(flags: flags(interrupter: false), tabs: [], learnTab: nil, updateGate: .none)
    #expect(config.isEnabled(.snoreInterrupter))

    config.releaseRemoteUpdates()
    #expect(!config.isEnabled(.snoreInterrupter))
  }

  @Test func onlyTheLatestHeldValuesApply() {
    let config = AppConfig.isolated()
    config.holdRemoteUpdates()
    config.apply(flags: flags(interrupter: false), tabs: [], learnTab: nil, updateGate: .none)
    config.apply(flags: flags(interrupter: true), tabs: [], learnTab: nil, updateGate: .none)

    config.releaseRemoteUpdates()

    #expect(config.isEnabled(.snoreInterrupter))
  }

  @Test func valuesApplyImmediatelyWhenNotHeld() {
    let config = AppConfig.isolated()
    config.apply(flags: flags(interrupter: false), tabs: [], learnTab: nil, updateGate: .none)
    #expect(!config.isEnabled(.snoreInterrupter))
  }

  @Test func aRecordingHoldsRemoteValuesFromStartToStop() async throws {
    let config = AppConfig.isolated()
    let controller = SessionRecordingController(
      audioRecorder: FakeAudioRecorder(),
      snoreInterrupterPlayer: FakeSnoreInterrupterPlayer(),
      preferences: UserPreferences.isolated(),
      pendingSessionStore: FakePendingSessionStore(),
      checkpointStore: FakeSessionCheckpointStore(),
      rawLogWriter: FakeSessionRawLogWriter(),
      appConfig: config,
      runsProcessingLoop: false)

    try controller.startSession()
    #expect(config.isHoldingRemoteUpdates)
    config.apply(flags: flags(interrupter: false), tabs: [], learnTab: nil, updateGate: .none)
    #expect(config.isEnabled(.snoreInterrupter))

    _ = await controller.stopSession()
    #expect(!config.isHoldingRemoteUpdates)
    #expect(!config.isEnabled(.snoreInterrupter))
  }

  @Test func theMelodyDoesNotPlayWhenTheInterrupterIsOffRemotely() {
    let config = AppConfig.isolated()
    config.apply(flags: flags(interrupter: false), tabs: [], learnTab: nil, updateGate: .none)
    let preferences = UserPreferences.isolated()
    preferences.snoreInterrupterMode = .always
    let haptics = FakeHapticManager()
    let player = SnoreInterrupterPlayer(
      preferences: preferences, melodyStorage: FakeCustomMelodyStorage(), haptics: haptics, appConfig: config)

    player.playIfNeeded()

    #expect(!player.isPlaying)
    #expect(haptics.calls.isEmpty)
  }
}
