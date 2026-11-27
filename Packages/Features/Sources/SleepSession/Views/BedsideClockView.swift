import AudioEngine
import Config
import DesignSystem
import FactoryKit
import Models
import Services
import SleepGuardContentKit
import SleepGuardDesignKit
import SleepStore
import SleepStrings
import SwiftUI

@MainActor
struct BedsideClockView: View {
  @Injected(\.sessionManager) private var sessionManager
  @Injected(\.audioRecorder) private var audioRecorder
  @Injected(\.snoreInterrupterPlayer) private var snoreInterrupterPlayer
  @Injected(\.appConfig) private var appConfig
  @Injected(\.userPreferences) private var userPreferences

  @State private var currentTime = Date()
  @State private var showShortSessionAlert = false

  var body: some View {
    // The shared bedside content (ADR 0006); the melody disclaimer and the
    // melody controls go in its banner and overlay slots.
    BedsideClockContent(
      time: currentTime,
      elapsed: elapsed,
      eventCount: sessionManager.eventsCount,
      db: audioRecorder.currentDB,
      snoreState: sessionManager.currentDetectionState,
      onStop: stopTapped,
      banner: {
        if isMelodyEnabled, !snoreInterrupterPlayer.isMutedForSession {
          BedsideMelodyDisclaimer {
            snoreInterrupterPlayer.muteForSession()
          }
          .padding(.top, 10)
          .padding(.horizontal, 20)
        }
      },
      overlay: {
        if isMelodyEnabled, snoreInterrupterPlayer.isPlaying {
          BedsideMelodyOverlay(
            melodyName: snoreInterrupterPlayer.currentMelody?.name ?? Strings.snoreInterrupterDefaultMelodyName,
            onMute: { snoreInterrupterPlayer.muteForSession() },
            onStop: { snoreInterrupterPlayer.stop() })
        }
      })
      .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showShortSessionAlert) {
        Button(Strings.actionKeepRecording, role: .cancel) {}
        Button(Strings.actionStopAnyway) {
          sessionManager.stopAndDiscardSession()
        }
      } message: {
        Text(String(format: Strings.sessionSummaryTooShortMessageFormat, Int(NightRecord.minimumSaveDuration / 60)))
      }
      .task {
        while !Task.isCancelled {
          let now = Date()
          let newSecond = Calendar.current.component(.second, from: now)
          let oldSecond = Calendar.current.component(.second, from: currentTime)
          if newSecond != oldSecond {
            currentTime = now
          }
          try? await Task.sleep(for: .milliseconds(50))
        }
      }
  }

  // MARK: - Helpers

  /// Too early to keep: ask first. Otherwise stop and save.
  private func stopTapped() {
    if let session = sessionManager.currentSession,
       currentTime.timeIntervalSince(session.start) < NightRecord.minimumSaveDuration
    {
      showShortSessionAlert = true
    } else {
      Task {
        _ = await sessionManager.stopSession()
      }
    }
  }

  private var elapsed: TimeInterval {
    sessionManager.currentSession.map { currentTime.timeIntervalSince($0.start) } ?? 0
  }

  private var isMelodyEnabled: Bool {
    appConfig.isEnabled(.snoreInterrupter) && userPreferences.snoreInterrupterMode.isOn
  }
}
