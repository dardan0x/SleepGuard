import SwiftUI
import AudioEngine
import Env
import Models
import DesignSystem

@MainActor
struct BedsideClockView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(AudioRecorder.self) private var audioRecorder
  @Environment(AlarmManager.self) private var alarmManager
  @Environment(SoundAnalysisDetector.self) private var soundAnalysisDetector
  @Environment(Theme.self) private var theme

  @State private var currentTime = Date()
  @State private var showAlarmOverlay = false

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        BedsideClockBadgesView(
          eventsCount: sessionManager.eventsCount,
          isAlarmSet: alarmManager.isAlarmSet,
          alarmTimeString: alarmTimeString
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
          alarmManager.clearAlarm()
          _ = sessionManager.stopSession()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }

      if showAlarmOverlay {
        AlarmOverlayView(currentTime: currentTime) {
          showAlarmOverlay = false
        }
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
        let saConf = soundAnalysisDetector.snoreConfidence
        #if DEBUG
        if saConf > 0.1 {
          print("[BedsideClockView] passing db=\(String(format: "%.1f", audioRecorder.currentDB)) snoreConf=\(String(format: "%.3f", saConf))")
        }
        #endif
        sessionManager.processAudioLevel(
          db: audioRecorder.currentDB,
          spectralScore: audioRecorder.spectralScore,
          snoreConfidence: saConf
        )

        if alarmManager.evaluate(currentTime: now, snoringState: sessionManager.currentSnoringState) {
          showAlarmOverlay = true
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
    guard let session = sessionManager.currentSession else { return "0h 0m" }
    let duration = currentTime.timeIntervalSince(session.startDate)
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    return String(format: "%dh %02dm", hours, minutes)
  }

  private var alarmTimeString: String {
    guard let alarmTime = alarmManager.alarmTime else { return "" }
    return DateFormatters.timeWithPeriod.string(from: alarmTime)
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
    case .none: return "Quiet"
    case .quiet: return "Quiet snoring detected · just now"
    case .light: return "Light snoring detected · just now"
    case .loud: return "Loud snoring detected · just now"
    }
  }
}
