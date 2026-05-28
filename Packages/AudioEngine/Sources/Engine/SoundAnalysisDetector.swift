import SoundAnalysis
import AVFoundation
import Observation

/// Wraps Apple's built-in SNAudioStreamAnalyzer to detect snoring
/// using the pre-trained 300-class sound classifier shipped with iOS.
@MainActor
@Observable
public final class SoundAnalysisDetector: NSObject, SNResultsObserving {
  public static let shared = SoundAnalysisDetector()

  /// Confidence that the current audio contains snoring (0–1).
  public var snoreConfidence: Float = 0

  /// Confidence that the current audio contains speech (0–1).
  public var speechConfidence: Float = 0

  /// Whether snoring was detected in the built-in classifier.
  public var isSnoringClassAvailable = false

  private var streamAnalyzer: SNAudioStreamAnalyzer?
  private var analysisRequest: SNClassifySoundRequest?
  private let snoreIdentifiers = ["snore", "snoring"]
  private let speechIdentifiers = [
    "speech", "talking", "conversation", "narration", "monologue",
    "whisper", "mumble", "mutter", "stutter",
    "groan", "moan", "sigh", "grunt", "grumble",
    "exclaim", "gasp", "yell", "scream", "shout",
    "laugh", "giggle", "whimper"
  ]
  private let babyIdentifiers = ["baby_crying", "baby_laughter", "babble"]

  private override init() {
    super.init()
    setupRequest()
  }

  private func setupRequest() {
    do {
      let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
      analysisRequest = request

      let known = request.knownClassifications.map { $0.lowercased() }
      print("[SoundAnalysis] Built-in sound classes: \(known.sorted())")

      let found = snoreIdentifiers.first { known.contains($0) }
      if let found {
        isSnoringClassAvailable = true
        print("[SoundAnalysis] Found snoring-related class: '\(found)'")
      } else {
        isSnoringClassAvailable = false
        print("[SoundAnalysis] Snoring NOT in built-in classes. FFT fallback will be used.")
      }
    } catch {
      print("[SoundAnalysis] Failed to create request: \(error)")
    }
  }

  /// Starts the stream analyzer with the audio format.
  public func startAnalyzing(format: AVAudioFormat) {
    guard let request = analysisRequest else { return }

    streamAnalyzer = SNAudioStreamAnalyzer(format: format)
    do {
      try streamAnalyzer?.add(request, withObserver: self)
    } catch {
      print("[SoundAnalysis] Failed to add request: \(error)")
    }
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

  /// Feeds a buffer to the analyzer.
  public func analyze(buffer: AVAudioPCMBuffer, at framePosition: AVAudioFramePosition) {
    guard let streamAnalyzer else { return }
    do {
      try streamAnalyzer.analyze(buffer, atAudioFramePosition: framePosition)
    } catch {
      print("[SoundAnalysis] Analyze error: \(error)")
    }
  }

  // MARK: - SNResultsObserving

  nonisolated public func request(
    _ request: SNRequest,
    didProduce result: SNResult
  ) {
    guard let result = result as? SNClassificationResult else { return }

    // Print top 3 classifications for diagnostics.
    let top3 = result.classifications.prefix(3).map {
      "\($0.identifier): \(String(format: "%.3f", $0.confidence))"
    }.joined(separator: ", ")
    print("[SoundAnalysis] Top classifications: \(top3)")

    var maxSnoreConfidence: Float = 0
    var maxSpeechConfidence: Float = 0
    for classification in result.classifications {
      let id = classification.identifier.lowercased()
      if snoreIdentifiers.contains(where: { id.contains($0) }) {
        maxSnoreConfidence = max(maxSnoreConfidence, Float(classification.confidence))
      }
      if speechIdentifiers.contains(where: { id.contains($0) }) {
        maxSpeechConfidence = max(maxSpeechConfidence, Float(classification.confidence))
      }
      if babyIdentifiers.contains(where: { id.contains($0) }) {
        maxSpeechConfidence = max(maxSpeechConfidence, Float(classification.confidence))
      }
    }

    Task { @MainActor in
      self.snoreConfidence = maxSnoreConfidence
      self.speechConfidence = maxSpeechConfidence
      #if DEBUG
      if maxSnoreConfidence > 0 {
        print("[SoundAnalysis] snoreConfidence updated: \(String(format: "%.3f", maxSnoreConfidence))")
      }
      if maxSpeechConfidence > 0 {
        print("[SoundAnalysis] speechConfidence updated: \(String(format: "%.3f", maxSpeechConfidence))")
      }
      #endif
    }
  }

  nonisolated public func request(
    _ request: SNRequest,
    didFailWithError error: Error
  ) {
    print("[SoundAnalysis] Request failed: \(error.localizedDescription)")
  }

  nonisolated public func requestDidComplete(_ request: SNRequest) {}
}
