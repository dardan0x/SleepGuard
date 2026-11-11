import AVFoundation
import Observation
import SoundAnalysis

/// Apple SoundAnalysis classifier confidences for snoring and speech.
/// Fake: `FakeSoundAnalysisDetector` (EnvTestSupport).
@MainActor
public protocol SoundAnalysisDetecting: AnyObject, Observable {
  var snoreConfidence: Float { get }
  var speechConfidence: Float { get }
  var isSnoringClassAvailable: Bool { get }
  func startAnalyzing(format: AVAudioFormat) -> SNAudioStreamAnalyzer?
  func stopAnalyzing()
}
