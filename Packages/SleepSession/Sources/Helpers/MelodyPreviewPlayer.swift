import FactoryKit
import Foundation
import Models
import Services
import SleepAudioKit
import SleepCore

/// Short preview playback for the melody picker: plays a melody for up to
/// 3 s (SleepGuardShared's `MelodyPlayback`, quieter, no nudge) and tracks
/// which melody is currently previewing.
@MainActor
@Observable
final class MelodyPreviewPlayer {
  private(set) var previewingMelodyID: Int?

  private let playback = MelodyPlayback(volume: 0.8, nudge: nil)
  private let melodyStorage: any CustomMelodyStoring

  init(melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage()) {
    self.melodyStorage = melodyStorage
  }

  /// Toggles preview of the given melody: previews it, or stops if it is
  /// already the previewing one.
  func preview(_ melody: Melody) {
    if previewingMelodyID == melody.id {
      stop()
      return
    }
    stop()
    guard let fileURL = melodyStorage.url(for: melody),
          playback.play(fileURL, loops: false, duration: 3, onFinish: { [weak self] in self?.previewingMelodyID = nil })
    else { return }
    previewingMelodyID = melody.id
  }

  func stop() {
    playback.stop()
    previewingMelodyID = nil
  }
}
