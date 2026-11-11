import Foundation
import Models
import Observation

/// Plays the snore-interrupter melody. Fake: `FakeSnoreInterrupterPlayer`.
@MainActor
public protocol SnoreInterrupterPlaying: AnyObject, Observable {
  var isPlaying: Bool { get }
  var currentMelodyName: String? { get }
  var isMutedForSession: Bool { get }
  func playIfNeeded()
  func stop()
  func muteForSession()
  func resetSessionMute()
}
