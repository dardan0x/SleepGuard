import FactoryKit
import Foundation
import Models
import Services
import SleepAudioKit
import SleepCore
import SleepLogging

/// Recording engine for the custom-melody sheet: the take is recorded and
/// played back by SleepGuardShared's `MelodyRecording` and `MelodyPlayback`
/// (the same as SleepGuardUIKitWay's); this keeps the elapsed time and the
/// record → recorded state machine. The view renders `state`/`elapsed` and
/// forwards button taps.
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

  private let melodyStorage: any CustomMelodyStoring
  private let recording = MelodyRecording()
  private let playback = MelodyPlayback(volume: 0.8, nudge: nil)
  private var recordedURL: URL?
  private var timer: Task<Void, Never>?

  init(melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage()) {
    self.melodyStorage = melodyStorage
  }

  /// Checks (or requests) microphone permission. Call on appear.
  func checkPermission() {
    Task { permissionGranted = await recording.requestPermission() }
  }

  /// Starts a new take, replacing any previous recording. It stops by itself
  /// at SleepCore's maximum length.
  func startRecording() {
    cleanup()
    do {
      try recording.start(onLimit: { [weak self] in self?.stopRecording() })
    } catch {
      Log.interrupter.error("Failed to start recording: \(String(describing: error), privacy: .public)")
      return
    }
    state = .recording
    elapsed = 0
    timer = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(100))
        guard let self, state == .recording else { return }
        elapsed = recording.elapsed
      }
    }
  }

  func stopRecording() {
    timer?.cancel()
    timer = nil
    recordedURL = recording.stop()
    elapsed = recording.elapsed
    state = .recorded
  }

  /// Plays (or stops) the current take.
  func togglePlayback() {
    if isPlaying {
      playback.stop()
      isPlaying = false
      return
    }
    guard let url = recordedURL else { return }
    isPlaying = playback.play(url, loops: false, duration: nil, onFinish: { [weak self] in self?.isPlaying = false })
  }

  /// The number in the take's default name ("My Sound 3"); the view names it.
  var nameNumber: Int {
    CustomMelodies.nameNumber(existing: melodyStorage.customMelodies)
  }

  /// Persists the take via `CustomMelodyStorage` under `name`. Returns true
  /// when saved (the caller dismisses the sheet in that case).
  @discardableResult
  func save(name: String) -> Bool {
    guard let url = recordedURL else { return false }
    playback.stop()
    _ = melodyStorage.saveRecording(name: name, from: url)
    recordedURL = nil
    return true
  }

  /// Discards the take and returns to the idle state.
  func discardAndReset() {
    cleanup()
    state = .idle
    elapsed = 0
  }

  /// Stops everything and deletes the take. Call on disappear.
  func cleanup() {
    timer?.cancel()
    timer = nil
    playback.stop()
    isPlaying = false
    recording.discard()
    recordedURL = nil
  }
}
