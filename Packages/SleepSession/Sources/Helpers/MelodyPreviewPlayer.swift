import AVFoundation
import Env
import Foundation
import Models

/// Short preview playback for the melody picker: plays a melody for up to
/// 3 s and tracks which melody is currently previewing.
@MainActor
@Observable
final class MelodyPreviewPlayer {
  private(set) var previewingMelodyID: Int?

  private var previewPlayer: AVAudioPlayer?
  private var previewTask: Task<Void, Never>?

  /// Toggles preview of the given melody: previews it, or stops if it is
  /// already the previewing one.
  func preview(_ melody: Melody) {
    if previewingMelodyID == melody.id {
      stop()
      return
    }

    stop()

    let url: URL? = if melody.isCustom {
      CustomMelodyStorage.shared.fileURL(for: melody)
    } else {
      Bundle.main.url(forResource: melody.filename, withExtension: "mp3", subdirectory: "sounds")
        ?? Bundle.main.url(forResource: melody.filename, withExtension: "mp3")
    }

    guard let fileURL = url else { return }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)

      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.volume = 0.8
      previewPlayer = player
      previewingMelodyID = melody.id

      guard player.prepareToPlay() else { return }
      let didPlay = player.play()
      guard didPlay else {
        previewingMelodyID = nil
        previewPlayer = nil
        return
      }

      previewTask?.cancel()
      previewTask = Task {
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        stop()
      }
    } catch {
      previewingMelodyID = nil
      previewPlayer = nil
    }
  }

  func stop() {
    previewTask?.cancel()
    previewTask = nil
    previewPlayer?.stop()
    previewPlayer = nil
    previewingMelodyID = nil
  }
}
