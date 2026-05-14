import SwiftUI
import AudioEngine
import Env
import Models
import DesignSystem

@MainActor
struct BedsideClockView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(AudioRecorder.self) private var audioRecorder
  @Environment(SoundAnalysisDetector.self) private var soundAnalysisDetector
  @Environment(Theme.self) private var theme

  @State private var currentTime = Date()
  @State private var showShortSessionAlert = false

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        BedsideClockBadgesView(
          eventsCount: sessionManager.eventsCount
        )

        Spacer()

        BedsideClockClockView(
          timeString: timeString,
          dateString: dateString
        )

        Spacer()

        BedsideClockWaveformView(
          durationString: durationString,
          levels: simulatedWaveform
        )

        Spacer()

        BedsideClockStatusView(
          statusLabel: statusLabel,
          snoringColor: snoringColor
        )

        Spacer()

        StopRecordingButton(height: 52) {
          if let session = sessionManager.currentSession,
             currentTime.timeIntervalSince(session.startDate) < SleepSession.minimumSaveDuration {
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
      .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showShortSessionAlert) {
        Button(Strings.actionKeepRecording, role: .cancel) { }
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

  private var timeString: String {
    DateFormatters.time.string(from: currentTime)
  }

  private var dateString: String {
    DateFormatters.weekdayAndMonthDay.string(from: currentTime).uppercased()
  }

  private var durationString: String {
    guard let session = sessionManager.currentSession else { return "0 min" }
    let duration = currentTime.timeIntervalSince(session.startDate)
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }

  private var simulatedWaveform: [Double] {
    let baseLevel = Double(max(0, (audioRecorder.currentDB + 60) / 40))
    return (0..<9).map { index in
      let variation = sin(Double(index) * 1.3 + Date().timeIntervalSince1970 * 5) * 0.3
      return max(0.1, min(1.0, baseLevel + variation))
    }
  }

  private var snoringColor: Color {
    switch sessionManager.currentSnoringState {
    case .none: return theme.textTertiary
    case .quiet: return theme.snoreQuiet
    case .light: return theme.snoreLight
    case .loud: return theme.snoreLoud
    }
  }

  private var statusLabel: String {
    switch sessionManager.currentSnoringState {
    case .none: return Strings.statsCalendarIntensityQuiet
    case .quiet: return Strings.sessionBedsideSnoreQuiet
    case .light: return Strings.sessionBedsideSnoreLight
    case .loud: return Strings.sessionBedsideSnoreLoud
    }
  }
}
