import AudioEngine
import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

/// Plays individual snore-event audio clips presented as a bottom sheet.
/// Always opens in expanded mode — shows the full event player with waveform
/// and controls. Clip sessions play through `ClipPlaybackController`; legacy
/// sessions (no per-event clips) export the event on demand via
/// `LegacyClipPlayer`.
@MainActor
public struct PlayerSheetView: View {
  let session: SleepSession
  let sortedEvents: [SnoreEvent]
  let isClipSession: Bool
  let initialEvent: SnoreEvent?

  @Injected(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss

  @State private var playbackController = ClipPlaybackController()
  @State private var legacyPlayer = LegacyClipPlayer()
  @State private var waveformLoader = WaveformLoader()
  /// Controls become enabled after 3 s even if the legacy export is still
  /// running, so the UI never appears stuck.
  @State private var isReady = false
  @State private var loadState: PlayerLoadState = .loading

  private var playerNavigationTitle: String {
    let event = playbackController.currentEvent ?? initialEvent
    guard let event else { return Strings.eventPlayerNavigationTitle }
    switch event.category {
    case .snoring: return Strings.eventPlayerNavigationTitle
    case .sleepTalking: return Strings.eventPlayerSleepTalkingTitle
    case .noise, .coughing, .other: return Strings.eventPlayerNoiseTitle
    }
  }

  /// Resolves the session's full audio source, preferring the legacy file and
  /// falling back to the raw archive (used after clip extraction moves it).
  private var sessionAudioURL: URL? {
    AudioFileURLResolver.resolve(session.audioFileURL)
      ?? AudioFileURLResolver.resolve(session.rawAudioFileURL)
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          switch loadState {
          case .loading:
            PlayerLoadingSkeleton()
          case .ready:
            readyContent
          case let .noAudio(event):
            if let event {
              NoAudioView(event: event)
            }
          }
        }
        .padding(20)
      }
      .background(theme.bgPrimary.ignoresSafeArea())
      // Was `.height(470)` — bumped so the Enhanced Audio toggle below the
      // player controls is visible without scrolling. `.large` is also offered
      // so users can drag up for more breathing room if they want.
      .presentationDetents([.height(580), .large])
      .presentationDragIndicator(.visible)
      .navigationTitle(playerNavigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(theme.textTertiary)
          }
        }
      }
    }
    .task {
      await setup()
    }
    .onDisappear {
      playbackController.cleanup()
      legacyPlayer.stop()
    }
  }

  @ViewBuilder
  private var readyContent: some View {
    if isClipSession {
      ClipPlayerContent(
        controller: playbackController,
        waveformSamples: waveformLoader.samples,
        isReady: isReady,
        isLoadingWaveform: waveformLoader.isLoading,
        sortedEvents: sortedEvents,
        onSelectEvent: { event, index in
          playbackController.playEvent(at: index)
          waveformLoader.load(for: event, sessionAudioURL: sessionAudioURL, sessionStart: session.startDate)
        })
    } else if let initialEvent {
      LegacyPlayerContent(
        player: legacyPlayer,
        event: initialEvent,
        waveformSamples: waveformLoader.samples,
        isReady: isReady,
        isLoadingWaveform: waveformLoader.isLoading)
    }
  }

  private func setup() async {
    let readinessTask = Task {
      try? await Task.sleep(for: .seconds(3))
      if !Task.isCancelled {
        isReady = true
      }
    }
    // Safety net: after 10 s of no playable audio, fall through to the
    // no-audio state so the skeleton can't be stuck forever. If the export
    // later completes with audio, the final state below overwrites this.
    let skeletonSafetyTask = Task {
      try? await Task.sleep(for: .seconds(10))
      if !Task.isCancelled, case .loading = loadState {
        loadState = .noAudio(playbackController.currentEvent ?? initialEvent)
      }
    }

    // Initialize the enhancement toggle from the persisted user preference
    // BEFORE loading the first clip — `setupPlayerForCurrentEvent` reads
    // `enhancedAudioEnabled` to compute per-clip normalization gain.
    playbackController.enhancedAudioEnabled = UserPreferences.shared.enhancedAudioPlayback

    if isClipSession {
      playbackController.loadEvents(sortedEvents)
      if let initialEvent, let index = sortedEvents.firstIndex(where: { $0.id == initialEvent.id }) {
        waveformLoader.load(for: initialEvent, sessionAudioURL: sessionAudioURL, sessionStart: session.startDate)
        if playbackController.hasAudioForCurrentEvent {
          playbackController.playEvent(at: index)
        }
      } else if let firstEvent = sortedEvents.first {
        waveformLoader.load(for: firstEvent, sessionAudioURL: sessionAudioURL, sessionStart: session.startDate)
        if playbackController.hasAudioForCurrentEvent {
          playbackController.playEvent(at: 0)
        }
      }
      loadState = playbackController.currentEvent != nil && playbackController.hasAudioForCurrentEvent
        ? .ready
        : .noAudio(playbackController.currentEvent ?? initialEvent)
    } else if let initialEvent {
      await legacyPlayer.prepare(
        event: initialEvent,
        sessionURL: sessionAudioURL,
        sessionStart: session.startDate)
      waveformLoader.load(for: initialEvent, sessionAudioURL: sessionAudioURL, sessionStart: session.startDate)
      loadState = legacyPlayer.duration > 0 ? .ready : .noAudio(initialEvent)
    } else {
      loadState = .noAudio(nil)
    }

    readinessTask.cancel()
    skeletonSafetyTask.cancel()
    isReady = true
  }
}

private enum PlayerLoadState {
  case loading
  case ready
  case noAudio(SnoreEvent?)
}
