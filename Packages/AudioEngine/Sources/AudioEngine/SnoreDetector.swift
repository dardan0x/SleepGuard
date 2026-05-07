import AVFoundation
import CoreML
import Observation

public enum SnoringState: Sendable {
  case none
  case quiet
  case light
  case loud
}

@MainActor
@Observable
public final class SnoreDetector {
  public static let shared = SnoreDetector()

  public var currentState: SnoringState = .none

  /// Thresholds in dB. Used as fallback when CoreML is unavailable.
  public var quietThreshold: Float = -40.0
  public var lightThreshold: Float = -30.0
  public var loudThreshold: Float = -20.0

  /// Confidence threshold derived from detection sensitivity.
  /// Higher sensitivity → lower confidence required (more detections).
  public var confidenceThreshold: Float = 0.6

  /// Whether CoreML classification is enabled.
  public var useCoreML: Bool = true

  private var classifier: SnoreClassifier?

  private init() {
    loadModel()
  }

  private func loadModel() {
    do {
      let configuration = MLModelConfiguration()
      configuration.computeUnits = .cpuOnly
      classifier = try SnoreClassifier(configuration: configuration)
    } catch {
      // Model failed to load; fall back to threshold-based detection.
      classifier = nil
      useCoreML = false
    }
  }

  // MARK: - Public Classification

  public func classify(db: Float) -> SnoringState {
    if useCoreML, let classifier {
      return classifyWithCoreML(db: db, classifier: classifier)
    }
    return classifyWithThresholds(db: db)
  }

  public func update(db: Float) {
    currentState = classify(db: db)
  }

  // MARK: - Threshold Fallback

  public func classifyWithThresholds(db: Float) -> SnoringState {
    if db >= loudThreshold {
      return .loud
    } else if db >= lightThreshold {
      return .light
    } else if db >= quietThreshold {
      return .quiet
    }
    return .none
  }

  // MARK: - CoreML Classification

  private func classifyWithCoreML(db: Float, classifier: SnoreClassifier) -> SnoringState {
    do {
      let array = try MLMultiArray(shape: [1], dataType: .double)
      array[0] = NSNumber(value: db)
      let input = SnoreClassifierInput(decibel: array)
      let output = try classifier.prediction(input: input)
      return state(from: output.intensityProbs)
    } catch {
      // Prediction failed; fall back to thresholds.
      return classifyWithThresholds(db: db)
    }
  }

  /// Maps the 4-element probability vector to the most likely state
  /// that also meets the confidence threshold.
  ///
  /// Output indices: [none, quiet, light, loud]
  private func state(from probs: MLMultiArray) -> SnoringState {
    guard probs.count == 4 else {
      return .none
    }

    // Find the index with the highest probability.
    var maxIndex = 0
    var maxValue: Double = probs[0].doubleValue
    for i in 1..<4 {
      let val = probs[i].doubleValue
      if val > maxValue {
        maxValue = val
        maxIndex = i
      }
    }

    // Require minimum confidence.
    guard Float(maxValue) >= confidenceThreshold else {
      return .none
    }

    switch maxIndex {
    case 1: return .quiet
    case 2: return .light
    case 3: return .loud
    default: return .none
    }
  }
}
