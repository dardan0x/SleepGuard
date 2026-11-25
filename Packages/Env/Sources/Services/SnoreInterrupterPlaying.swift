import Foundation
import Models
public import Observation
public import SleepCore

/// Plays the snore-interrupter melody. Fake: `FakeSnoreInterrupterPlayer`.
@MainActor
public protocol SnoreInterrupterPlaying: AnyObject, Observable {
  var isPlaying: Bool { get }
  /// The melody playing now (the view names it).
  var currentMelody: Melody? { get }
  var isMutedForSession: Bool { get }
  func playIfNeeded()
  func stop()
  func muteForSession()
  func resetSessionMute()
}
