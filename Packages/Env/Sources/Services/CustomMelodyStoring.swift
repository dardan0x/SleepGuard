import Foundation
import Models
import Observation

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
