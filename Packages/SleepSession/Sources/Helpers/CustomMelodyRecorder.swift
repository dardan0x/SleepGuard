import AVFoundation
import Env
import FactoryKit
import Foundation

/// Recording engine for the custom-melody sheet: owns the audio recorder,
/// the elapsed-time timer, playback of the take, and the record → recorded
/// state machine. The view renders `state`/`elapsed` and forwards button
/// taps.
@MainActor
@Observable
final class CustomMelodyRecorder {
  enum RecordingState {
    case idle
    case recording
    case recorded
  }

  private(set) var state: RecordingState = .idle
  private(set) var elapsed: TimeInterval = 0
  private(set) var isPlaying = false
  private(set) var permissionGranted = false

  private let maxDuration: TimeInterval = 10
  private let melodyStorage: any CustomMelodyStoring
  private var recorder: AVAudioRecorder?
  private var recordedURL: URL?
  private var playbackPlayer: AVAudioPlayer?
  private var timer: Timer?

  init(melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage()) {
    self.melodyStorage = melodyStorage
  }

  /// Checks (or requests) microphone permission. Call on appear.
  func checkPermission() {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      permissionGranted = true
    case .denied:
      permissionGranted = false
    case .undetermined:
      Task {
        let granted = await withCheckedContinuation { continuation in
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
          }
        }
        permissionGranted = granted
      }
    @unknown default:
      permissionGranted = false
    }
  }

  /// Starts a new take, replacing any previous recording.
  func startRecording() {
    cleanup()

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
      try session.setActive(true)
    } catch {
      print("[RecordCustomMelodySheet] Failed to configure session: \(error)")
      return
    }

    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("custom_melody_temp.m4a")
    if FileManager.default.fileExists(atPath: tempURL.path) {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    do {
      let rec = try AVAudioRecorder(url: tempURL, settings: settings)
      rec.record()
      recorder = rec
      recordedURL = tempURL
      state = .recording
      elapsed = 0

      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak rec] _ in
        Task { @MainActor in
          guard let rec, rec.isRecording else { return }
          self.elapsed = rec.currentTime
          if rec.currentTime >= self.maxDuration {
            self.stopRecording()
          }
        }
      }
    } catch {
      print("[RecordCustomMelodySheet] Failed to start recording: \(error)")
    }
  }

  func stopRecording() {
    timer?.invalidate()
    timer = nil
    recorder?.stop()
    elapsed = recorder?.currentTime ?? elapsed
    recorder = nil
    state = .recorded

    try? AVAudioSession.sharedInstance().setActive(false)
  }

  /// Plays (or stops) the current take.
  func togglePlayback() {
    if isPlaying {
      playbackPlayer?.stop()
      playbackPlayer = nil
      isPlaying = false
      return
    }

    guard let url = recordedURL else { return }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = 0.8
      player.play()
      playbackPlayer = player
      isPlaying = true

      Task {
        try? await Task.sleep(for: .seconds(player.duration + 0.1))
        playbackPlayer = nil
        isPlaying = false
      }
    } catch {
      print("[RecordCustomMelodySheet] Failed to play back: \(error)")
    }
  }

  /// Persists the take via `CustomMelodyStorage`. Returns true when saved
  /// (the caller dismisses the sheet in that case).
  @discardableResult
  func save() -> Bool {
    guard let url = recordedURL else { return false }
    let name = "My Sound \(melodyStorage.allCustomMelodies().count + 1)"
    _ = melodyStorage.saveRecording(name: name, from: url)
    return true
  }

  /// Discards the take and returns to the idle state.
  func discardAndReset() {
    cleanup()
    state = .idle
    elapsed = 0
    recordedURL = nil
  }

  /// Stops everything and deletes the temp file. Call on disappear.
  func cleanup() {
    timer?.invalidate()
    timer = nil
    recorder?.stop()
    recorder = nil
    playbackPlayer?.stop()
    playbackPlayer = nil
    isPlaying = false
    if let url = recordedURL {
      try? FileManager.default.removeItem(at: url)
      recordedURL = nil
    }
  }
}
