import AVFoundation
public import Foundation
public import Observation
import SleepAudioKit
import SleepCore

/// Converts dBFS (negative digital scale) to a 0-100 percentage for UI display.
/// -60 dB → 0%, -20 dB → 100%.
public func audioLevelPercentage(from db: Double) -> Int {
  let normalized = (db + 60.0) / 40.0
  return Int(max(0.0, min(100.0, normalized * 100.0)))
}

public func audioLevelPercentage(from db: Float) -> Int {
  audioLevelPercentage(from: Double(db))
}

/// SleepGuard's capture: SleepGuardShared's `CaptureEngine` (the same as
/// SleepGuardUIKitWay's), with the levels published for the screens and the
/// detection callbacks. The engine owns the audio session, the tap, the clip
/// files, interruptions and route changes; this keeps what the screens read.
@MainActor
@Observable
public final class AudioRecorder: AudioRecording {
  public var isRecording = false
  public var isPaused = false
  public var isWarmedUp = false
  public var currentDB: Float = -160.0
  /// Peak dB of the current buffer (0 dBFS = digital full scale). Tracks impulsive
  /// peaks better than RMS `currentDB`, which is used for intensity classification.
  public var currentPeakDB: Float = -160.0
  /// Spectral snore-likelihood score (0–1); 0 unless the raw night is kept.
  public var spectralScore: Float = 0
  public private(set) var snoreConfidence: Float = 0
  public private(set) var speechConfidence: Float = 0
  public var hasPermission = false
  public private(set) var currentEventID: UUID?
  /// Called on the main actor for every buffer, after the levels above
  /// update, with the time the buffer arrived. Drives detection's sampling.
  public var onLevels: (@MainActor (Date) -> Void)?
  /// Called when the system interrupts capture (`true`, e.g. a call) and when
  /// capture runs again (`false`), with the time it happened.
  public var onCaptureInterruption: (@MainActor (_ interrupted: Bool, _ at: Date) -> Void)?

  @ObservationIgnored private let engine: CaptureEngine
  @ObservationIgnored private let clipsDirectory: URL
  @ObservationIgnored private var events: Task<Void, Never>?

  /// Event clips and the raw night are written to `clipsDirectory`.
  public init(clipsDirectory: URL) {
    self.clipsDirectory = clipsDirectory
    engine = CaptureEngine(clipsDirectory: clipsDirectory)
    checkPermission()
    // The Snore Interrupter's melody pauses the microphone, so the app doesn't
    // hear itself. A stop without a pause (the night ending) resumes nothing.
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleMelodyWillPlay), name: .snoreInterrupterWillPlay, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleMelodyDidStop), name: .snoreInterrupterDidStop, object: nil)
  }

  @objc private func handleMelodyWillPlay() {
    pauseRecording()
  }

  @objc private func handleMelodyDidStop() {
    resumeRecording()
  }

  public func checkPermission() {
    #if targetEnvironment(simulator)
    hasPermission = true
    #else
    hasPermission = AVAudioApplication.shared.recordPermission == .granted
    #endif
  }

  public func requestPermission() async -> Bool {
    #if targetEnvironment(simulator)
    hasPermission = true
    return true
    #else
    hasPermission = await engine.requestPermission()
    return hasPermission
    #endif
  }

  public func startRecording(rawAudioFileName: String? = nil) throws {
    guard hasPermission else { return }
    let stream = try engine.start(rawAudioFileName: rawAudioFileName)
    isRecording = true
    isPaused = false
    events = Task { [weak self] in
      for await event in stream {
        self?.handle(event)
      }
    }
  }

  public func pauseRecording() {
    guard isRecording else { return }
    engine.pause()
    isPaused = engine.isPaused
  }

  public func resumeRecording() {
    engine.resume()
    isPaused = engine.isPaused
  }

  public func startEventFile(eventID: UUID) throws {
    try engine.startClip(id: eventID)
    currentEventID = eventID
  }

  public func finalizeEventFile() -> URL? {
    currentEventID = nil
    return engine.closeClip().map(clipsDirectory.appendingPathComponent)
  }

  public func discardEventFile() {
    currentEventID = nil
    engine.discardClip()
  }

  /// An event clip still open stays open for `finalizeEventFile` or
  /// `discardEventFile`: the night's last event is finalized after this.
  public func stopRecording() {
    engine.stop()
    events?.cancel()
    events = nil
    isRecording = false
    isPaused = false
    currentDB = -160.0
    currentPeakDB = -160.0
    spectralScore = 0
    snoreConfidence = 0
    speechConfidence = 0
  }

  // MARK: - Warmup (keeps audio I/O alive during a delayed-start countdown)

  /// Keeps the microphone running without listening while the recording
  /// delay counts down, so the app stays eligible for background audio.
  public func startWarmup() throws {
    guard hasPermission, !isWarmedUp else { return }
    try engine.warmUp()
    isWarmedUp = true
  }

  /// Ends the warm-up; the session stays active if a night is recording.
  public func stopWarmup() {
    guard isWarmedUp else { return }
    engine.coolDown()
    isWarmedUp = false
  }

  private func handle(_ event: CaptureEvent) {
    switch event {
    case let .sample(sample):
      currentDB = sample.db
      currentPeakDB = sample.peakDB
      spectralScore = sample.spectralScore
      snoreConfidence = sample.snoreConfidence
      speechConfidence = sample.speechConfidence
      onLevels?(sample.time)
    case let .interrupted(at):
      onCaptureInterruption?(true, at)
    case let .resumed(at):
      onCaptureInterruption?(false, at)
    }
  }
}
