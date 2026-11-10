import AVFoundation
import FactoryKit
import Models
import Observation

/// Plays the snore-interrupter melody. Fake: `FakeSnoreInterrupterPlayer`.
@MainActor
public protocol SnoreInterrupterPlaying: AnyObject, Observable {
  var isPlaying: Bool { get }
  var currentMelodyName: String? { get }
  var isMutedForSession: Bool { get }
  func playIfNeeded()
  func stop()
  func muteForSession()
  func resetSessionMute()
}

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
    print("[SnoreInterrupterPlayer] playIfNeeded() called — isMutedForSession=\(isMutedForSession), isPlaying=\(isPlaying)")

    guard !isMutedForSession else {
      print("[SnoreInterrupterPlayer] Muted for this session, skipping")
      return
    }

    guard !isPlaying else {
      print("[SnoreInterrupterPlayer] Already playing, skipping re-trigger")
      return
    }

    let mode = preferences.snoreInterrupterMode
    print("[SnoreInterrupterPlayer] Mode: \(mode)")
    guard mode != .never else {
      print("[SnoreInterrupterPlayer] Mode is .never, skipping")
      return
    }

    let melodyID = preferences.selectedMelodyID
    print("[SnoreInterrupterPlayer] Selected melody ID: \(melodyID)")

    let melody = Melody.melody(id: melodyID)
      ?? melodyStorage.melody(id: melodyID)

    guard let melody else {
      print("[SnoreInterrupterPlayer] No melody found for ID \(melodyID)")
      return
    }

    let url: URL? = if melody.isCustom {
      melodyStorage.fileURL(for: melody)
    } else {
      Bundle.main.url(forResource: melody.filename, withExtension: "mp3", subdirectory: "sounds")
        ?? Bundle.main.url(forResource: melody.filename, withExtension: "mp3")
    }

    guard let fileURL = url else {
      print("[SnoreInterrupterPlayer] Sound file not found: \(melody.filename).mp3")
      let bundlePath = Bundle.main.bundlePath
      let soundsPath = (bundlePath as NSString).appendingPathComponent("sounds")
      if FileManager.default.fileExists(atPath: soundsPath) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: soundsPath)) ?? []
        print("[SnoreInterrupterPlayer] Available sounds: \(files)")
      } else {
        print("[SnoreInterrupterPlayer] sounds/ directory does not exist at \(soundsPath)")
      }
      return
    }

    print("[SnoreInterrupterPlayer] Found sound at \(fileURL.path)")

    NotificationCenter.default.post(name: .snoreInterrupterWillPlay, object: nil)

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
      print("[SnoreInterrupterPlayer] Audio session activated with .playback")

      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.volume = 1.0
      player.numberOfLoops = mode == .always ? -1 : 0
      player.delegate = self
      audioPlayer = player
      currentMelodyName = melody.name
      print("[SnoreInterrupterPlayer] AVAudioPlayer created, delegate set")

      guard player.prepareToPlay() else {
        print("[SnoreInterrupterPlayer] prepareToPlay() returned false")
        NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: nil)
        return
      }
      print("[SnoreInterrupterPlayer] prepareToPlay() succeeded")

      let didPlay = player.play()
      print("[SnoreInterrupterPlayer] play() returned \(didPlay)")
      guard didPlay else {
        NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: nil)
        return
      }

      isPlaying = true
      print("[SnoreInterrupterPlayer] ✅ Started playing '\(melody.name)' for \(mode.displayLabel)")

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
      print("[SnoreInterrupterPlayer] ❌ Failed to play: \(error)")
      NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: nil)
    }
  }

  /// Stops playback immediately and cleans up.
  public func stop() {
    print("[SnoreInterrupterPlayer] stop() called — isPlaying was \(isPlaying)")
    audioPlayer?.stop()
    audioPlayer?.delegate = nil
    audioPlayer = nil
    stopTimer?.invalidate()
    stopTimer = nil
    nudgeTimer?.invalidate()
    nudgeTimer = nil
    isPlaying = false
    currentMelodyName = nil
    print("[SnoreInterrupterPlayer] ✅ Stopped — isPlaying now \(isPlaying)")

    NotificationCenter.default.post(name: .snoreInterrupterDidStop, object: nil)
  }

  /// Stops the current melody and prevents any further playback during this recording session.
  public func muteForSession() {
    stop()
    isMutedForSession = true
    print("[SnoreInterrupterPlayer] Muted for remainder of session")
  }

  /// Resets the session mute flag. Called when a new recording session starts.
  public func resetSessionMute() {
    isMutedForSession = false
    print("[SnoreInterrupterPlayer] Session mute reset")
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
