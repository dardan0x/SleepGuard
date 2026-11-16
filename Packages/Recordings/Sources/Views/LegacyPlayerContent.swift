import AudioEngine
import DesignSystem
import Models
import SwiftUI

/// Player content for legacy sessions without per-event clips: the shared
/// `PlayerCard` driven by `LegacyClipPlayer`, which exported the event audio
/// on demand during the sheet's setup.
struct LegacyPlayerContent: View {
  let player: LegacyClipPlayer
  let event: SnoreEvent
  let waveformSamples: [Float]
  let isReady: Bool
  let isLoadingWaveform: Bool

  var body: some View {
    PlayerCard(
      clip: PlayerClip(event: event),
      number: 1,
      count: 1,
      isPlaying: player.isPlaying,
      currentTime: player.currentTime,
      totalDuration: player.duration,
      waveform: waveformSamples,
      isLoadingWaveform: isLoadingWaveform,
      isReady: isReady,
      onToggle: { player.toggle() },
      onBack: { player.skip(by: -15) },
      onForward: { player.skip(by: 15) },
      onSeek: { player.scrubTo(relative: $0) })
  }
}
