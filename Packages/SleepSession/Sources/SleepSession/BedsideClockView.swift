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
      theme.backgroundColor.ignoresSafeArea()

      snoringGlow

      VStack(spacing: 32) {
        snoringIndicator

        Spacer()

        clockSection

        Spacer()

        audioLevelSection

        stopButton
      }
      .padding(.vertical, 48)
      .padding(.horizontal, 32)
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

  // MARK: - Subviews

  private var snoringGlow: some View {
    snoringColor
      .opacity(sessionManager.currentSnoringState == .none ? 0 : 0.06)
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.4), value: sessionManager.currentSnoringState)
  }

  private var snoringIndicator: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(snoringColor)
        .frame(width: 10, height: 10)

      Text(snoringLabel)
        .font(.caption.bold())
        .foregroundStyle(snoringColor)
        .transition(.opacity)
    }
    .opacity(sessionManager.currentSnoringState == .none ? 0.4 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: sessionManager.currentSnoringState)
  }

  private var clockSection: some View {
    VStack(spacing: 12) {
      Text(timeString)
        .font(.system(size: 88, weight: .thin, design: .rounded))
        .foregroundStyle(theme.labelColor.opacity(0.8))
        .minimumScaleFactor(0.6)
        .monospacedDigit()

      Text(durationString)
        .font(.system(size: 22, weight: .medium, design: .rounded))
        .foregroundStyle(theme.secondaryLabelColor)
        .monospacedDigit()
    }
  }

  private var audioLevelSection: some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.surfaceColor)

          RoundedRectangle(cornerRadius: 4)
            .fill(snoringColor.opacity(0.9))
            .frame(width: max(0, geometry.size.width * audioLevelFraction))
            .animation(.linear(duration: 0.05), value: audioRecorder.currentDB)
        }
      }
      .frame(height: 8)

      HStack {
        Text(String(format: "%.0f dB", audioRecorder.currentDB))
          .font(.caption2.monospacedDigit())
          .foregroundStyle(theme.secondaryLabelColor)

        Spacer()
      }
    }
  }

  private var stopButton: some View {
    Button {
      _ = sessionManager.stopSession()
    } label: {
      Image(systemName: "stop.fill")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 64, height: 64)
        .background(
          Circle()
            .fill(Color.red.opacity(0.75))
        )
    }
  }

  // MARK: - Helpers

  private var timeString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: currentTime)
  }

  private var durationString: String {
    guard let session = sessionManager.currentSession else { return "00:00:00" }
    let duration = currentTime.timeIntervalSince(session.startDate)
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  private var audioLevelFraction: CGFloat {
    let minDB: Float = -60
    let maxDB: Float = -20
    let clamped = max(min(audioRecorder.currentDB, maxDB), minDB)
    return CGFloat((clamped - minDB) / (maxDB - minDB))
  }

  private var snoringColor: Color {
    switch sessionManager.currentSnoringState {
    case .none: return theme.secondaryLabelColor
    case .quiet: return theme.secondaryColor
    case .light: return Color.orange
    case .loud: return Color.red
    }
  }

  private var snoringLabel: String {
    switch sessionManager.currentSnoringState {
    case .none: return "Quiet"
    case .quiet: return "Snoring — Quiet"
    case .light: return "Snoring — Light"
    case .loud: return "Snoring — Loud"
    }
  }
}
