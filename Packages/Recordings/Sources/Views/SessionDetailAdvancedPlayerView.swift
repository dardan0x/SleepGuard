import SwiftUI
import Models
import DesignSystem

/// Expandable advanced player showing waveform, frequency spectrum, and spectral stats for a snore event clip.
struct SessionDetailAdvancedPlayerView: View {
  let event: SnoreEvent
  let waveformSamples: [Float]
  let spectrumBars: [Float]
  let onWaveformTap: (Double) -> Void
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 20) {
      waveformSection
      spectrumSection
      statsSection
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  // MARK: - Waveform

  private var waveformSection: some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        WaveformShape(samples: waveformSamples)
          .fill(theme.intensityColor(event.intensity).opacity(0.8))
          .frame(height: 80)
          .contentShape(Rectangle())
          .onTapGesture { location in
            let relative = Double(location.x / geometry.size.width)
            onWaveformTap(relative)
          }
      }
      .frame(height: 80)

      Text(Strings.recordingsPlayerSeekHint)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.textTertiary)
    }
  }

  // MARK: - Spectrum

  private var spectrumSection: some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<spectrumBars.count, id: \.self) { index in
            let height = max(CGFloat(spectrumBars[index]) * geometry.size.height, 2)
            RoundedRectangle(cornerRadius: 1)
              .fill(barColor(at: index, total: spectrumBars.count))
              .frame(height: height)
          }
        }
        .frame(height: 60)
      }
      .frame(height: 60)

      HStack {
      Text(Strings.recordingsPlayerFreq0)
        Spacer()
      Text(Strings.recordingsPlayerFreq500)
        Spacer()
      Text(Strings.recordingsPlayerFreq1k)
      }
      .font(.system(size: 9, weight: .medium))
      .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsPlayerSpectrumLabel)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.textTertiary)
    }
  }

  private func barColor(at index: Int, total: Int) -> Color {
    let ratio = Double(index) / Double(total - 1)
    if ratio < 0.33 {
      return theme.scoreGreen
    } else if ratio < 0.66 {
      return theme.scoreAmber
    } else {
      return theme.scoreRed
    }
  }

  // MARK: - Stats

  private var statsSection: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        StatBox(title: Strings.recordingsPlayerStatDuration, value: durationString(event.snoreDuration))
        StatBox(title: Strings.recordingsPlayerStatDominantFreq, value: frequencyString(event.dominantFrequency))
      }

      HStack(spacing: 12) {
        StatBox(title: Strings.recordingsPlayerStatSpectralCentroid, value: frequencyString(event.spectralCentroid))
        StatBox(title: Strings.recordingsPlayerStatLowFreqRatio, value: String(format: "%.0f%%", event.lowFreqRatio * 100))
      }
    }
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }

  private func frequencyString(_ hz: Double) -> String {
    if hz >= 1000 {
      return String(format: "%.1f kHz", hz / 1000)
    }
    return String(format: "%.0f Hz", hz)
  }
}

// MARK: - Waveform Shape

struct WaveformShape: Shape {
  let samples: [Float]

  func path(in rect: CGRect) -> Path {
    guard !samples.isEmpty else { return Path() }

    let width = rect.width
    let height = rect.height
    let midY = height / 2
    let step = width / CGFloat(samples.count - 1)

    var path = Path()
    path.move(to: CGPoint(x: 0, y: midY))

    // Top half
    for (index, sample) in samples.enumerated() {
      let x = CGFloat(index) * step
      let y = midY - CGFloat(sample) * midY
      path.addLine(to: CGPoint(x: x, y: y))
    }

    // Bottom half (mirror)
    for (index, sample) in samples.enumerated().reversed() {
      let x = CGFloat(index) * step
      let y = midY + CGFloat(sample) * midY
      path.addLine(to: CGPoint(x: x, y: y))
    }

    path.closeSubpath()
    return path
  }
}

// MARK: - Stat Box

struct StatBox: View {
  let title: String
  let value: String
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(theme.textPrimary)
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(theme.bgElevated)
    .cornerRadius(theme.radiusSmall)
  }
}
