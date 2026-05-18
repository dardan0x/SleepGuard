import SwiftUI
import Models
import DesignSystem

/// Single-event audio player matching the SnoreGuard design.
/// Shows event info, bar waveform with progress, and centered playback controls.
@MainActor
struct EventPlayerView: View {
  let event: SnoreEvent
  let waveformSamples: [Float]
  let isPlaying: Bool
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let eventNumber: Int
  let totalEvents: Int
  let onTogglePlayback: () -> Void
  let onSkipBack: () -> Void
  let onSkipForward: () -> Void
  let onScrub: (Double) -> Void
  let isReady: Bool
  let isLoadingWaveform: Bool

  @Environment(Theme.self) private var theme
  @State private var pulsePhase = false

  var body: some View {
    ZStack {
      VStack(spacing: 24) {
        headerSection
        waveformSection
        controlsSection
        legendSection
      }
      .padding(20)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)

      if !isReady {
        loadingOverlay
      }
    }
    .task(id: isLoadingWaveform) {
      guard isLoadingWaveform else { return }
      while !Task.isCancelled {
        withAnimation(.easeInOut(duration: 0.7)) {
          pulsePhase.toggle()
        }
        try? await Task.sleep(for: .seconds(0.7))
      }
    }
  }

  private var loadingOverlay: some View {
    VStack(spacing: 12) {
      ProgressView()
        .scaleEffect(1.2)
        .tint(theme.accent)
        Text(Strings.loadingAudioEventPlayerView)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(theme.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.bgCard.opacity(0.95))
    .cornerRadius(theme.radiusCard)
  }

  // MARK: - Header

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(eventTimeString)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textSecondary)

        Text(Strings.snoringEventHeaderPlayerView.uppercased())
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1.5)

      HStack(spacing: 8) {
        Text(durationString(totalDuration))
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(theme.textPrimary)

        Text("·")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.textSecondary)

        Text(intensityLabel)
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(intensityColor)
      }

      if totalEvents > 1 {
          Text("\(Strings.eventHeaderSectionTotalEvents) \(eventNumber) of \(totalEvents)")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var eventTimeString: String {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: event.timestamp)
    let minute = calendar.component(.minute, from: event.timestamp)
    let period = hour >= 12 ? "pm" : "am"
    let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
    return String(format: "%d:%02d %@", displayHour, minute, period)
  }

  // MARK: - Waveform

  private var waveformSection: some View {
    VStack(spacing: 12) {
      // Dots above waveform
      waveformMarkers

      // Bar waveform with progress indicator
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          if isLoadingWaveform {
            waveformPlaceholder(maxHeight: geometry.size.height)
          } else {
            HStack(alignment: .center, spacing: 2) {
              ForEach(0..<barCount, id: \.self) { index in
                let isPlayed = Double(index) / Double(barCount) <= progress
                waveformBar(
                  height: barHeight(at: index, maxHeight: geometry.size.height),
                  isPlayed: isPlayed
                )
              }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Current time indicator line
            Rectangle()
              .fill(Color.white)
              .frame(width: 2, height: geometry.size.height + 8)
              .offset(x: CGFloat(progress) * geometry.size.width - 1, y: 0)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
          guard !isLoadingWaveform else { return }
          let relative = Double(location.x / geometry.size.width)
          onScrub(relative)
        }
      }
      .frame(height: 80)

      // Time labels
      HStack {
        Text(timeString(0))
        Spacer()
        Text("\(timeString(currentTime)) / \(timeString(totalDuration))")
        Spacer()
        Text(timeString(totalDuration))
      }
      .font(.system(size: 12, weight: .medium, design: .monospaced))
      .foregroundStyle(theme.textSecondary)
      .monospacedDigit()
    }
  }

  private var waveformMarkers: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Marker dots at burst positions if available, otherwise one at start
        if let bursts = event.bursts, bursts.count > 1 {
          ForEach(bursts.indices, id: \.self) { index in
            let burst = bursts[index]
            let position = burst.startOffset / totalDuration
            Circle()
              .fill(intensityColor)
              .frame(width: 8, height: 8)
              .position(
                x: CGFloat(position) * geometry.size.width,
                y: geometry.size.height / 2
              )
          }
        } else {
          Circle()
            .fill(intensityColor)
            .frame(width: 8, height: 8)
            .position(x: 0, y: geometry.size.height / 2)
        }
      }
    }
    .frame(height: 12)
  }

  private var barCount: Int {
    max(min(waveformSamples.count, 80), 40)
  }

  private func barHeight(at index: Int, maxHeight: CGFloat) -> CGFloat {
    guard !waveformSamples.isEmpty else { return 2 }
    let sampleIndex = Int(Double(index) / Double(barCount) * Double(waveformSamples.count))
    guard waveformSamples.indices.contains(sampleIndex) else { return 2 }
    let sample = waveformSamples[sampleIndex]
    return max(CGFloat(sample) * maxHeight * 0.9, 3)
  }

  private func waveformPlaceholder(maxHeight: CGFloat) -> some View {
    HStack(alignment: .center, spacing: 2) {
      ForEach(0..<barCount, id: \.self) { index in
        // Use a deterministic pseudo-random height based on index so bars don't flicker
        let pseudoRandom = CGFloat((index * 7 + 13) % 17) / 16.0
        let height = max(pseudoRandom * maxHeight * 0.55, 4)
        waveformBar(height: height, isPlayed: false)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .opacity(pulsePhase ? 0.25 : 0.55)
  }

  private func waveformBar(height: CGFloat, isPlayed: Bool) -> some View {
    RoundedRectangle(cornerRadius: 1.5)
      .fill(isPlayed ? theme.accent : theme.bgElevated)
      .frame(maxWidth: .infinity)
      .frame(height: height)
  }

  private var progress: Double {
    guard totalDuration > 0 else { return 0 }
    return currentTime / totalDuration
  }

  // MARK: - Controls

  private var controlsSection: some View {
    HStack(spacing: 40) {
      // Skip back 15s
      Button {
        onSkipBack()
      } label: {
        Image(systemName: "gobackward.15")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }

      // Play/Pause
      Button {
        onTogglePlayback()
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.bgPrimary)
          .frame(width: 72, height: 72)
          .background(Color.white)
          .clipShape(Circle())
      }

      // Skip forward 15s
      Button {
        onSkipForward()
      } label: {
        Image(systemName: "goforward.15")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.textPrimary)
      }
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Legend

  private var legendSection: some View {
    HStack(spacing: 20) {
      HStack(spacing: 6) {
        Circle()
          .fill(theme.scoreAmber)
          .frame(width: 8, height: 8)
          Text(Strings.lightSnoreEventPlayerView)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }

      HStack(spacing: 6) {
        Circle()
          .fill(theme.scoreRed)
          .frame(width: 8, height: 8)
          Text(Strings.loudSnoreEventPlayerView)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
    }
  }

  // MARK: - Helpers

  private var intensityColor: Color {
    theme.intensityColor(event.intensity)
  }

  private var intensityLabel: String {
    switch event.intensity {
    case .quiet: return Strings.quietIntensityLabel
    case .light: return Strings.lightIntensityLabelEventPlayerView
    case .loud: return Strings.loudIntensityLabelEventPlayerView
    }
  }

  private func durationString(_ total: TimeInterval) -> String {
    let minutes = Int(total) / 60
    let seconds = Int(total) % 60
    if minutes > 0 {
      return "\(minutes)m \(seconds)s"
    }
    return "\(seconds)s"
  }

  private func timeString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let mins = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", mins, secs)
  }
}
