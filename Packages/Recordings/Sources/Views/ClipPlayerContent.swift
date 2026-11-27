import AudioEngine
import Config
import DesignSystem
import FactoryKit
import Models
import SleepGuardContentKit
import SleepStore
import SwiftUI

/// Player content for clip sessions: the shared `PlayerContent` (card with
/// waveform, enhanced audio, the event list) over `ClipPlaybackController`.
/// Selection plays the event and asks the parent to reload the waveform
/// (`onSelectEvent`).
struct ClipPlayerContent: View {
  @Injected(\.userPreferences) private var userPreferences
  let controller: ClipPlaybackController
  let waveformSamples: [Float]
  let isReady: Bool
  let isLoadingWaveform: Bool
  let sortedEvents: [NightEventRecord]
  let onSelectEvent: (NightEventRecord, Int) -> Void

  var body: some View {
    if controller.currentEvent != nil {
      PlayerContent(
        clips: sortedEvents.map(PlayerClip.init(event:)),
        index: controller.currentEventIndex,
        isPlaying: controller.isPlaying,
        currentTime: controller.currentTime,
        totalDuration: controller.totalClipsDuration,
        waveform: waveformSamples,
        isLoadingWaveform: isLoadingWaveform,
        isReady: isReady,
        isEnhanced: enhancedAudioBinding,
        onToggle: { controller.togglePlayback() },
        onSeek: { controller.seek(to: $0) },
        onSelect: { index in onSelectEvent(sortedEvents[index], index) })
    }
  }

  private var enhancedAudioBinding: Binding<Bool> {
    Binding(
      get: { controller.enhancedAudioEnabled },
      set: { newValue in
        controller.enhancedAudioEnabled = newValue
        userPreferences.enhancedAudioPlayback = newValue
      })
  }
}
