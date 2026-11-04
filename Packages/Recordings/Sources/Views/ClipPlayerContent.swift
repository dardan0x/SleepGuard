import AudioEngine
import Env
import Models
import SwiftUI

/// Player content for clip sessions: full event player, enhanced-audio
/// toggle, and the tappable event list. Selection plays the event and asks
/// the parent to reload the waveform (`onSelectEvent`).
struct ClipPlayerContent: View {
  let controller: ClipPlaybackController
  let waveformSamples: [Float]
  let isReady: Bool
  let isLoadingWaveform: Bool
  let sortedEvents: [SnoreEvent]
  let onSelectEvent: (SnoreEvent, Int) -> Void

  var body: some View {
    if let currentEvent = controller.currentEvent {
      EventPlayerView(
        event: currentEvent,
        waveformSamples: waveformSamples,
        isPlaying: controller.isPlaying,
        currentTime: controller.currentTime,
        totalDuration: controller.totalClipsDuration,
        eventNumber: controller.currentEventNumber,
        totalEvents: controller.totalEventCount,
        onTogglePlayback: { controller.togglePlayback() },
        onSkipBack: { skip(by: -15) },
        onSkipForward: { skip(by: 15) },
        onScrub: { relative in controller.seek(to: relative) },
        isReady: isReady,
        isLoadingWaveform: isLoadingWaveform
      )
      EnhancedAudioToggleSection(isOn: enhancedAudioBinding)
      if sortedEvents.count > 1 {
        PlayerEventListSection(
          events: sortedEvents,
          currentEventIndex: controller.currentEventIndex,
          isPlaying: controller.isPlaying,
          onSelect: { index in onSelectEvent(sortedEvents[index], index) }
        )
      }
    }
  }

  private var enhancedAudioBinding: Binding<Bool> {
    Binding(
      get: { controller.enhancedAudioEnabled },
      set: { newValue in
        controller.enhancedAudioEnabled = newValue
        UserPreferences.shared.enhancedAudioPlayback = newValue
      }
    )
  }

  private func skip(by seconds: TimeInterval) {
    let newTime = max(0, controller.currentTime + seconds)
    guard controller.totalClipsDuration > 0 else { return }
    controller.seek(to: newTime / controller.totalClipsDuration)
  }
}
