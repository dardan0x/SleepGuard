import SwiftUI
import AudioEngine
import Env
import DesignSystem

@MainActor
struct BedsideClockView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Theme.self) private var theme
  private let audioRecorder = AudioRecorder.shared

  @State private var currentTime = Date()

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        eventBadge
          .frame(maxWidth: .infinity, alignment: .trailing)
          .padding(.top, 16)
          .padding(.horizontal, 24)

        Spacer()

        clockSection

        Spacer()

        waveformSection

        Spacer()

        statusSection

        Spacer()

        stopButton
          .padding(.bottom, 32)
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
        sessionManager.processAudioLevel(db: audioRecorder.currentDB)
        try? await Task.sleep(for: .milliseconds(50))
      }
    }
  }

  private var eventBadge: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(theme.scoreGreen)
        .frame(width: 8, height: 8)
      Text("\(sessionManager.eventsCount) EVENTS")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.scoreGreen)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .overlay(
      RoundedRectangle(cornerRadius: 100)
        .stroke(theme.scoreGreen, lineWidth: 1)
    )
  }

  private var clockSection: some View {
    VStack(spacing: 8) {
      Text(timeString)
        .font(.system(size: 96, weight: .thin, design: .rounded))
        .foregroundStyle(theme.textTertiary)
        .minimumScaleFactor(0.5)
        .monospacedDigit()

      Text(dateString)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(theme.textSecondary)
        .tracking(2)
        .textCase(.uppercase)
    }
  }

  private var waveformSection: some View {
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Circle()
          .fill(theme.scoreGreen)
          .frame(width: 8, height: 8)
        Text("Recording · \(durationString)")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(theme.accent)
          .monospacedDigit()
      }

      AudioLevelMeter(
        levels: simulatedWaveform,
        theme: theme
      )
    }
  }

  private var statusSection: some View {
    VStack(spacing: 12) {
      HStack(spacing: 6) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 14))
          .foregroundStyle(snoringColor)
        Text(statusLabel)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(snoringColor)
      }

      Text(String(format: "%.0f dB · ambient", audioRecorder.currentDB))
        .font(.system(size: 20, weight: .regular, design: .rounded))
        .foregroundStyle(theme.textTertiary)
        .monospacedDigit()
    }
  }

  private var stopButton: some View {
    Button {
      _ = sessionManager.stopSession()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "stop.fill")
          .font(.system(size: 18, weight: .semibold))
        Text("Stop Recording")
          .font(.system(size: 17, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(theme.destructive)
      .clipShape(Capsule())
    }
    .padding(.horizontal, 24)
  }

  // MARK: - Helpers

  private var timeString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm"
    return formatter.string(from: currentTime)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE · MMM d"
    return formatter.string(from: currentTime).uppercased()
  }

  private var durationString: String {
    guard let session = sessionManager.currentSession else { return "0h 0m" }
    let duration = currentTime.timeIntervalSince(session.startDate)
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    return String(format: "%dh %02dm", hours, minutes)
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
