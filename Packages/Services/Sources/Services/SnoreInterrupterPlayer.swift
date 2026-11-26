import AudioEngine
public import Config
public import FactoryKit
import Foundation
import Models
public import Observation
public import Platform
public import SleepCore
import SleepAudioKit

/// Plays the selected Snore Interrupter when snoring is detected.
/// Respects the user's duration preference and exposes `isPlaying` for UI observation.
/// Plays through SleepGuardShared's `MelodyPlayback` (the same as
/// SleepGuardUIKitWay's): at night in the capture's `.playAndRecord` session,
/// with the haptic nudge every 2 s.
@MainActor
@Observable
public final class SnoreInterrupterPlayer: SnoreInterrupterPlaying {
  public static let shared = SnoreInterrupterPlayer()

  public var isPlaying = false
  public var currentMelody: Melody?
  /// When true, no melody will play for the remainder of the current recording session.
  public var isMutedForSession = false

  @ObservationIgnored private var playback: MelodyPlayback?

  private let preferences: any UserPreferencesStoring
  private let melodyStorage: any CustomMelodyStoring
  private let haptics: any HapticFeedbackProviding
  private let appConfig: any AppConfigProviding

  public init(
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage(),
    haptics: any HapticFeedbackProviding = Container.shared.hapticManager(),
    appConfig: any AppConfigProviding = Container.shared.appConfig())
  {
    self.appConfig = appConfig
    self.preferences = preferences
    self.melodyStorage = melodyStorage
    self.haptics = haptics
  }

  /// Call when a new snore event is detected. Checks preferences and starts playback
  /// if a melody is configured and nothing is already playing.
  public func playIfNeeded() {
    Log.interrupter.debug("playIfNeeded() called — isMutedForSession=\(self.isMutedForSession), isPlaying=\(self.isPlaying)")
    guard !isMutedForSession else {
      Log.interrupter.debug("Muted for this session, skipping")
      return
    }

    guard !isPlaying else {
      Log.interrupter.debug("Already playing, skipping re-trigger")
      return
    }

    // The remote switch, frozen for the night (`AppConfig.holdRemoteUpdates`),
    // so the melody and its Mute/Stop controls are on or off together.
    guard appConfig.isEnabled(.snoreInterrupter) else {
      Log.interrupter.debug("Interrupter disabled remotely, skipping")
      return
    }

    let mode = preferences.snoreInterrupterMode
    Log.interrupter.debug("Mode: \(String(describing: mode), privacy: .public)")
    guard mode.isOn else {
      Log.interrupter.debug("Mode is .never, skipping")
      return
    }

    let melodyID = preferences.selectedMelodyID
    Log.interrupter.debug("Selected melody ID: \(melodyID)")
    let melody = melodyStorage.resolve(id: melodyID)
    guard let fileURL = melodyStorage.url(for: melody) else {
      Log.interrupter.error("Sound file not found: \(melody.filename, privacy: .public)")
      return
    }

    Log.interrupter.debug("Found sound at \(fileURL.path)")
    // The microphone pauses first (`AudioRecorder`), so the app doesn't hear itself.
    NotificationCenter.default.post(name: .snoreInterrupterWillPlay, object: nil)

    haptics.prepare()
    let playback = MelodyPlayback(nudge: { [weak self] in self?.haptics.nudge() })
    guard playback.play(fileURL, loops: mode.loops, duration: mode.playDuration, onFinish: { [weak self] in self?.stop() }) else {
      Log.interrupter.error("Melody didn't start")
      NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: self)
      return
    }
    self.playback = playback
    currentMelody = melody
    isPlaying = true
    Log.interrupter.info("Started playing melody \(melody.id) (\(mode.rawValue, privacy: .public))")
  }

  /// Stops playback immediately and cleans up.
  public func stop() {
    Log.interrupter.debug("stop() called — isPlaying was \(self.isPlaying)")
    playback?.stop()
    playback = nil
    isPlaying = false
    currentMelody = nil
    Log.interrupter.info("Stopped — isPlaying now \(self.isPlaying)")
    NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: self)
  }

  /// Stops the current melody and prevents any further playback during this recording session.
  public func muteForSession() {
    stop()
    isMutedForSession = true
    Log.interrupter.info("Muted for remainder of session")
  }

  /// Resets the session mute flag. Called when a new recording session starts.
  public func resetSessionMute() {
    isMutedForSession = false
    Log.interrupter.info("Session mute reset")
  }
}
