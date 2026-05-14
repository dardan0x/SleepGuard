import AVFoundation
import Observation
import Models

/// Plays the selected soothing melody when snoring is detected.
/// Respects the user's duration preference and exposes `isPlaying` for UI observation.
@MainActor
@Observable
public final class SoothingMelodyPlayer: NSObject {
  public static let shared = SoothingMelodyPlayer()

  public var isPlaying = false
  public var currentMelodyName: String?
  /// When true, no melody will play for the remainder of the current recording session.
  public var isMutedForSession = false

  private var audioPlayer: AVAudioPlayer?
  private var stopTimer: Timer?

  private override init() {
    super.init()
  }

  /// Call when a new snore event is detected. Checks preferences and starts playback
  /// if a melody is configured and nothing is already playing.
  public func playIfNeeded() {
    print("[SoothingMelodyPlayer] playIfNeeded() called — isMutedForSession=\(isMutedForSession), isPlaying=\(isPlaying)")

    guard !isMutedForSession else {
      print("[SoothingMelodyPlayer] Muted for this session, skipping")
      return
    }

    guard !isPlaying else {
      print("[SoothingMelodyPlayer] Already playing, skipping re-trigger")
      return
    }

    let mode = UserPreferences.shared.soothingMelodyMode
    print("[SoothingMelodyPlayer] Mode: \(mode)")
    guard mode != .never else {
      print("[SoothingMelodyPlayer] Mode is .never, skipping")
      return
    }

    let melodyID = UserPreferences.shared.selectedMelodyID
    print("[SoothingMelodyPlayer] Selected melody ID: \(melodyID)")

    let melody = Melody.melody(id: melodyID)
      ?? CustomMelodyStorage.shared.melody(id: melodyID)

    guard let melody else {
      print("[SoothingMelodyPlayer] No melody found for ID \(melodyID)")
      return
    }

    let url: URL?
    if melody.isCustom {
      url = CustomMelodyStorage.shared.fileURL(for: melody)
    } else {
      url = Bundle.main.url(forResource: melody.filename, withExtension: "mp3", subdirectory: "sounds")
        ?? Bundle.main.url(forResource: melody.filename, withExtension: "mp3")
    }

    guard let fileURL = url else {
      print("[SoothingMelodyPlayer] Sound file not found: \(melody.filename).mp3")
      let bundlePath = Bundle.main.bundlePath
      let soundsPath = (bundlePath as NSString).appendingPathComponent("sounds")
      if FileManager.default.fileExists(atPath: soundsPath) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: soundsPath)) ?? []
        print("[SoothingMelodyPlayer] Available sounds: \(files)")
      } else {
        print("[SoothingMelodyPlayer] sounds/ directory does not exist at \(soundsPath)")
      }
      return
    }

    print("[SoothingMelodyPlayer] Found sound at \(fileURL.path)")

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setActive(true)
      print("[SoothingMelodyPlayer] Audio session activated")
      try session.overrideOutputAudioPort(.speaker)
      print("[SoothingMelodyPlayer] Output port overridden to speaker")

      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.volume = 0.6
      player.numberOfLoops = mode == .always ? -1 : 0
      player.delegate = self
      audioPlayer = player
      currentMelodyName = melody.name
      print("[SoothingMelodyPlayer] AVAudioPlayer created, delegate set")

      guard player.prepareToPlay() else {
        print("[SoothingMelodyPlayer] prepareToPlay() returned false")
        return
      }
      print("[SoothingMelodyPlayer] prepareToPlay() succeeded")

      let didPlay = player.play()
      print("[SoothingMelodyPlayer] play() returned \(didPlay)")
      guard didPlay else {
        return
      }

      isPlaying = true
      print("[SoothingMelodyPlayer] ✅ Started playing '\(melody.name)' for \(mode.displayLabel)")

      if mode != .always {
        let duration = mode.duration
        stopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
          Task { @MainActor in
            self?.stop()
          }
        }
      }
    } catch {
      print("[SoothingMelodyPlayer] ❌ Failed to play: \(error)")
    }
  }

  /// Stops playback immediately and cleans up.
  public func stop() {
    print("[SoothingMelodyPlayer] stop() called — isPlaying was \(isPlaying)")
    audioPlayer?.stop()
    audioPlayer?.delegate = nil
    audioPlayer = nil
    stopTimer?.invalidate()
    stopTimer = nil
    isPlaying = false
    currentMelodyName = nil
    print("[SoothingMelodyPlayer] ✅ Stopped — isPlaying now \(isPlaying)")
  }

  /// Stops the current melody and prevents any further playback during this recording session.
  public func muteForSession() {
    stop()
    isMutedForSession = true
    print("[SoothingMelodyPlayer] Muted for remainder of session")
  }

  /// Resets the session mute flag. Called when a new recording session starts.
  public func resetSessionMute() {
    isMutedForSession = false
    print("[SoothingMelodyPlayer] Session mute reset")
  }
}

extension SoothingMelodyPlayer: AVAudioPlayerDelegate {
  nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      self.stop()
    }
  }
}

private extension UserPreferences.SoothingMelodyMode {
  var duration: TimeInterval {
    switch self {
    case .never, .always: return 0
    case .fiveSeconds: return 5
    case .fifteenSeconds: return 15
    case .thirtySeconds: return 30
    case .sixtySeconds: return 60
    }
  }
}
