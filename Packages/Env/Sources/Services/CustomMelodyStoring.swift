import Foundation
import Models
import Observation
import SleepCore
import SleepMelodies

/// User-recorded interrupter melodies on disk. Fake: `FakeCustomMelodyStorage`.
@MainActor
public protocol CustomMelodyStoring: AnyObject, Observable {
  var customMelodies: [Melody] { get }
  func allCustomMelodies() -> [Melody]
  func melody(id: Int) -> Melody?
  func melody(filename: String) -> Melody?
  @discardableResult
  func saveRecording(name: String, from tempURL: URL) -> Melody?
  func deleteMelody(id: Int)
  func fileURL(for melody: Melody) -> URL?
}

public extension CustomMelodyStoring {
  /// The sound file for any melody: a recording from this store, a built-in
  /// from the shared `SleepMelodies`.
  func url(for melody: Melody) -> URL? {
    melody.isCustom ? fileURL(for: melody) : SleepMelodies.url(for: melody)
  }

  /// The melody for a stored id, falling back to the default (SleepCore's rule).
  func resolve(id: Int) -> Melody {
    Melody.resolve(id: id, custom: customMelodies)
  }
}
