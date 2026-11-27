public import Foundation
import Models
public import Observation
public import SleepCore
import SleepAudioKit

/// The user's recorded melodies: SleepGuardShared's `MelodyFiles` (the same
/// as SleepGuardUIKitWay's) in the Melodies folder of the shared layout, with
/// the list kept here for the screens.
@MainActor
@Observable
public final class CustomMelodyStorage: CustomMelodyStoring {
  public static let shared = CustomMelodyStorage()

  public private(set) var customMelodies: [Melody] = []

  @ObservationIgnored private let files: MelodyFiles

  /// `nil`: SleepGuard's Melodies folder (`SleepGuardStorage`); the contract
  /// tests pass a throwaway one.
  public init(directory: URL? = nil) {
    files = MelodyFiles(directory: directory ?? SleepGuardStorage.location.melodiesDirectory)
    customMelodies = files.recordings()
  }

  // MARK: - Public API

  public func allCustomMelodies() -> [Melody] {
    customMelodies
  }

  public func melody(id: Int) -> Melody? {
    customMelodies.first { $0.id == id }
  }

  public func melody(filename: String) -> Melody? {
    customMelodies.first { $0.filename == filename }
  }

  /// Saves a recorded audio file (moved) as a new custom melody.
  @discardableResult
  public func saveRecording(name: String, from tempURL: URL) -> Melody? {
    let melody = files.save(take: tempURL, name: name)
    customMelodies = files.recordings()
    return melody
  }

  public func deleteMelody(id: Int) {
    guard let melody = melody(id: id) else { return }
    files.delete(melody)
    customMelodies = files.recordings()
  }

  public func fileURL(for melody: Melody) -> URL? {
    guard melody.isCustom else { return nil }
    return files.url(for: melody)
  }
}
