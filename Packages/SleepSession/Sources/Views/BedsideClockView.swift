import AudioEngine
import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

@MainActor
struct BedsideClockView: View {
  @Injected(\.sessionManager) private var sessionManager
  @Injected(\.audioRecorder) private var audioRecorder
  @Injected(\.snoreInterrupterPlayer) private var snoreInterrupterPlayer
  @Injected(\.appConfig) private var appConfig
  @Injected(\.theme) private var theme
  @Injected(\.userPreferences) private var userPreferences

  @State private var currentTime = Date()
  @State private var showShortSessionAlert = false

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        VStack(spacing: 8) {
          HStack {
            Spacer()
            BedsideEventsBadge(count: sessionManager.eventsCount)
          }
          .padding(.top, 16)
          .padding(.horizontal, 24)

          if isMelodyEnabled, !snoreInterrupterPlayer.isMutedForSession {
            BedsideMelodyDisclaimer {
              snoreInterrupterPlayer.muteForSession()
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
          }
        }

        Spacer()

        BedsideClockFace(time: currentTime)

        Spacer()

        BedsideRecordingStatus(elapsed: elapsed, db: audioRecorder.currentDB, time: currentTime)

        Spacer()

        BedsideSnoreStatus(state: sessionManager.currentDetectionState)

        Spacer()

        StopRecordingButton(height: 52) {
          if let session = sessionManager.currentSession,
             currentTime.timeIntervalSince(session.startDate) < SleepSession.minimumSaveDuration
          {
            showShortSessionAlert = true
          } else {
            Task {
              _ = await sessionManager.stopSession()
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
      .overlay(alignment: .top) {
        if isMelodyEnabled, snoreInterrupterPlayer.isPlaying {
          BedsideMelodyOverlay(
            melodyName: snoreInterrupterPlayer.currentMelodyName ?? Strings.snoreInterrupterDefaultMelodyName,
            onMute: { snoreInterrupterPlayer.muteForSession() },
            onStop: { snoreInterrupterPlayer.stop() })
        }
      }
      .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showShortSessionAlert) {
        Button(Strings.actionKeepRecording, role: .cancel) {}
        Button(Strings.actionStopAnyway) {
          sessionManager.stopAndDiscardSession()
        }
      } message: {
        Text(String(format: Strings.sessionSummaryTooShortMessageFormat, Int(SleepSession.minimumSaveDuration / 60)))
      }
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

  private var elapsed: TimeInterval {
    sessionManager.currentSession.map { currentTime.timeIntervalSince($0.startDate) } ?? 0
  }

  private var isMelodyEnabled: Bool {
    appConfig.isEnabled(.snoreInterrupter) && userPreferences.snoreInterrupterMode != .never
  }
}
