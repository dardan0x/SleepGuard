import AVFoundation
import FactoryKit
import Models
import Observation

/// Plays the selected Snore Interrupter when snoring is detected.
/// Respects the user's duration preference and exposes `isPlaying` for UI observation.
@MainActor
@Observable
public final class SnoreInterrupterPlayer: NSObject, SnoreInterrupterPlaying {
  public static let shared = SnoreInterrupterPlayer()

  public var isPlaying = false
  public var currentMelodyName: String?
  /// When true, no melody will play for the remainder of the current recording session.
  public var isMutedForSession = false

  private var audioPlayer: AVAudioPlayer?
  private var stopTimer: Timer?
  private var nudgeTimer: Timer?

  private let preferences: any UserPreferencesStoring
  private let melodyStorage: any CustomMelodyStoring
  private let haptics: any HapticFeedbackProviding

  public init(
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage(),
    haptics: any HapticFeedbackProviding = Container.shared.hapticManager())
  {
    self.preferences = preferences
    self.melodyStorage = melodyStorage
    self.haptics = haptics
    super.init()
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

    let mode = preferences.snoreInterrupterMode
    Log.interrupter.debug("Mode: \(String(describing: mode), privacy: .public)")
    guard mode != .never else {
      Log.interrupter.debug("Mode is .never, skipping")
      return
    }

    let melodyID = preferences.selectedMelodyID
    Log.interrupter.debug("Selected melody ID: \(melodyID)")
    let melody = Melody.melody(id: melodyID)
      ?? melodyStorage.melody(id: melodyID)

    guard let melody else {
      Log.interrupter.debug("No melody found for ID \(melodyID)")
      return
    }

    let url: URL? = if melody.isCustom {
      melodyStorage.fileURL(for: melody)
    } else {
      Bundle.main.url(forResource: melody.filename, withExtension: "mp3", subdirectory: "sounds")
        ?? Bundle.main.url(forResource: melody.filename, withExtension: "mp3")
    }

    guard let fileURL = url else {
      Log.interrupter.error("Sound file not found: \(melody.filename).mp3")
      let bundlePath = Bundle.main.bundlePath
      let soundsPath = (bundlePath as NSString).appendingPathComponent("sounds")
      if FileManager.default.fileExists(atPath: soundsPath) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: soundsPath)) ?? []
        Log.interrupter.debug("Available sounds: \(files)")
      } else {
        Log.interrupter.error("sounds/ directory does not exist at \(soundsPath)")
      }
      return
    }

    Log.interrupter.debug("Found sound at \(fileURL.path)")
    NotificationCenter.default.post(name: .snoreInterrupterWillPlay, object: nil)

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
      Log.interrupter.debug("Audio session activated with .playback")
      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.volume = 1.0
      player.numberOfLoops = mode == .always ? -1 : 0
      player.delegate = self
      audioPlayer = player
      currentMelodyName = melody.name
      Log.interrupter.debug("AVAudioPlayer created, delegate set")
      guard player.prepareToPlay() else {
        Log.interrupter.error("prepareToPlay() returned false")
        NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: self)
        return
      }
      Log.interrupter.debug("prepareToPlay() succeeded")
      let didPlay = player.play()
      Log.interrupter.debug("play() returned \(didPlay)")
      guard didPlay else {
        NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: self)
        return
      }

      isPlaying = true
      Log.interrupter.info("Started playing '\(melody.name)' for \(mode.displayLabel)")
      haptics.prepare()
      haptics.nudge()
      nudgeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
          self?.haptics.nudge()
        }
      }

      if mode != .always {
        let duration = mode.duration
        stopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
          Task { @MainActor in
            self?.stop()
          }
        }
      }
    } catch {
      Log.interrupter.error("Failed to play: \(String(describing: error), privacy: .public)")
      NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: self)
    }
  }

  /// Stops playback immediately and cleans up.
  public func stop() {
    Log.interrupter.debug("stop() called — isPlaying was \(self.isPlaying)")
    audioPlayer?.stop()
    audioPlayer?.delegate = nil
    audioPlayer = nil
    stopTimer?.invalidate()
    stopTimer = nil
    nudgeTimer?.invalidate()
    nudgeTimer = nil
    isPlaying = false
    currentMelodyName = nil
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

extension SnoreInterrupterPlayer: AVAudioPlayerDelegate {
  public nonisolated func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
    Task { @MainActor in
      self.stop()
    }
  }
}

private extension UserPreferences.SnoreInterrupterMode {
  var duration: TimeInterval {
    switch self {
    case .never, .always: 0
    case .fiveSeconds: 5
    case .fifteenSeconds: 15
    case .thirtySeconds: 30
    case .sixtySeconds: 60
    }
  }
}
