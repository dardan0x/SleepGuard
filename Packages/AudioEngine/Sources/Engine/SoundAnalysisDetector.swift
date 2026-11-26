public import AVFoundation
import SleepLogging
public import Observation
import SleepCore
public import SoundAnalysis

/// Wraps Apple's built-in SNAudioStreamAnalyzer to detect snoring
/// using the pre-trained 300-class sound classifier shipped with iOS.
@MainActor
@Observable
public final class SoundAnalysisDetector: NSObject, SNResultsObserving, SoundAnalysisDetecting {
  public static let shared = SoundAnalysisDetector()

  /// Confidence that the current audio contains snoring (0–1).
  public var snoreConfidence: Float = 0

  /// Confidence that the current audio contains speech (0–1).
  public var speechConfidence: Float = 0

  /// Whether snoring was detected in the built-in classifier.
  public var isSnoringClassAvailable = false

  private var streamAnalyzer: SNAudioStreamAnalyzer?
  private var analysisRequest: SNClassifySoundRequest?
  override public init() {
    super.init()
    setupRequest()
  }

  private func setupRequest() {
    do {
      let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
      analysisRequest = request

      let known = request.knownClassifications.map { $0.lowercased() }
      Log.audio.debug("Built-in sound classes: \(known.sorted())")
      let found = SoundClassLabels.snore.first { known.contains($0) }
      if let found {
        isSnoringClassAvailable = true
        Log.audio.info("Found snoring-related class: '\(found)'")
      } else {
        isSnoringClassAvailable = false
        Log.audio.notice("Snoring NOT in built-in classes. FFT fallback will be used.")
      }
    } catch {
      Log.audio.error("Failed to create request: \(String(describing: error), privacy: .public)")
    }
  }

  /// Starts the stream analyzer with the audio format. Returns the analyzer so
  /// the audio-thread `TapProcessor` can feed it buffers directly.
  @discardableResult
  public func startAnalyzing(format: AVAudioFormat) -> SNAudioStreamAnalyzer? {
    guard let request = analysisRequest else { return nil }

    streamAnalyzer = SNAudioStreamAnalyzer(format: format)
    do {
      try streamAnalyzer?.add(request, withObserver: self)
    } catch {
      Log.audio.error("Failed to add request: \(String(describing: error), privacy: .public)")
    }
    return streamAnalyzer
  }

  /// Stops analysis and cleans up.
  public func stopAnalyzing() {
    if let request = analysisRequest {
      streamAnalyzer?.remove(request)
    }
    streamAnalyzer = nil
    snoreConfidence = 0
    speechConfidence = 0
  }

  // MARK: - SNResultsObserving

  public nonisolated func request(
    _: SNRequest,
    didProduce result: SNResult)
  {
    guard let result = result as? SNClassificationResult else { return }

    #if DEBUG
    // Top 3 classifications for diagnostics. Built only in Debug: this runs
    // for every result, about twice a second all night.
    let top3 = result.classifications.prefix(3).map {
      "\($0.identifier): \(String(format: "%.3f", $0.confidence))"
    }.joined(separator: ", ")
    Log.audio.debug("Top classifications: \(top3, privacy: .public)")
    #endif
    // Which classes count as snoring and talking: SleepCore's `SoundClassLabels`.
    let confidences = SoundClassLabels.confidences(result.classifications.map { ($0.identifier, $0.confidence) })
    let maxSnoreConfidence = confidences.snore
    let maxSpeechConfidence = confidences.speech

    Task { @MainActor in
      self.snoreConfidence = maxSnoreConfidence
      self.speechConfidence = maxSpeechConfidence
      #if DEBUG
      if maxSnoreConfidence > 0 {
        Log.audio.debug("snoreConfidence updated: \(maxSnoreConfidence, format: .fixed(precision: 3))")
      }
      if maxSpeechConfidence > 0 {
        Log.audio.debug("speechConfidence updated: \(maxSpeechConfidence, format: .fixed(precision: 3))")
      }
      #endif
    }
  }

  public nonisolated func request(
    _: SNRequest,
    didFailWithError error: Error)
  {
    Log.audio.error("Request failed: \(error.localizedDescription, privacy: .public)")
  }

  public nonisolated func requestDidComplete(_: SNRequest) {}
}
