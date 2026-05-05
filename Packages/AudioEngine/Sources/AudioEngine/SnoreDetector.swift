import AVFoundation
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

  /// Thresholds in dB. Adjustable via UserPreferences.
  public var quietThreshold: Float = -40.0
  public var lightThreshold: Float = -30.0
  public var loudThreshold: Float = -20.0

  private init() {}

  public func classify(db: Float) -> SnoringState {
    if db >= loudThreshold {
      return .loud
    } else if db >= lightThreshold {
      return .light
    } else if db >= quietThreshold {
      return .quiet
    }
    return .none
  }

  public func update(db: Float) {
    currentState = classify(db: db)
  }
}
