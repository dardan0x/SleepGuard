import AudioEngine
import Models
import SwiftUI

/// Player content for legacy sessions without per-event clips: full event
/// player driven by `LegacyClipPlayer`, which exported the event audio on
/// demand during the sheet's setup.
struct LegacyPlayerContent: View {
  let player: LegacyClipPlayer
  let event: SnoreEvent
  let waveformSamples: [Float]
  let isReady: Bool
  let isLoadingWaveform: Bool

  var body: some View {
    EventPlayerView(
      event: event,
      waveformSamples: waveformSamples,
      isPlaying: player.isPlaying,
      currentTime: player.currentTime,
      totalDuration: player.duration,
      eventNumber: 1,
      totalEvents: 1,
      onTogglePlayback: { player.toggle() },
      onSkipBack: { player.skip(by: -15) },
      onSkipForward: { player.skip(by: 15) },
      onScrub: { relative in player.scrubTo(relative: relative) },
      isReady: isReady,
      isLoadingWaveform: isLoadingWaveform)
  }
}
