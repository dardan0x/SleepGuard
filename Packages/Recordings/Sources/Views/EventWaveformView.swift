import DesignSystem
import Models
import SwiftUI

/// Bar waveform with progress indicator and tap-to-scrub for the event
/// player. Shows a deterministic placeholder with a loading pulse while
/// samples are being generated.
struct EventWaveformView: View {
  @Environment(Theme.self) private var theme

  let event: SnoreEvent
  let intensityColor: Color
  let waveformSamples: [Float]
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let isLoadingWaveform: Bool
  let onScrub: (Double) -> Void

  @State private var pulsePhase = false

  var body: some View {
    VStack(spacing: 12) {
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
                  isPlayed: isPlayed)
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

  // NOTE: `waveformMarkers` (burst-span capsules above the waveform) is
  // kept verbatim from the monolith — its only call site is commented out
  // in the original design. Safe to delete if burst markers are not coming
  // back.
  private var waveformMarkers: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Burst-span markers: each capsule spans the burst's actual start→end
        // duration so users can directly read which segments of the waveform
        // the detector classified as snoring (vs. just where it began).
        // Burst offsets are relative to THIS event's start — divide by
        // `event.snoreDuration`, NOT `totalDuration` (which is the whole
        // session in multi-event mode and would cluster spans at the left).
        // Falls back to a single dot at the start when burst data is missing
        // (legacy events recorded before the burst model existed).
        if let bursts = event.bursts, !bursts.isEmpty, event.snoreDuration > 0 {
          ForEach(bursts.indices, id: \.self) { index in
            let burst = bursts[index]
            let startPos = burst.startOffset / event.snoreDuration
            let endPos = min(burst.endOffset / event.snoreDuration, 1.0)
            let startX = CGFloat(startPos) * geometry.size.width
            // Minimum 6 pt wide so very short bursts stay visible at all sizes.
            let widthPx = max(CGFloat(endPos - startPos) * geometry.size.width, 6)
            Capsule()
              .fill(intensityColor)
              .frame(width: widthPx, height: 6)
              .position(x: startX + widthPx / 2, y: geometry.size.height / 2)
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

  private func timeString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let mins = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", mins, secs)
  }
}
