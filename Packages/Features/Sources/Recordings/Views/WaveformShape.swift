import SwiftUI

/// Filled symmetric waveform shape (top samples mirrored below the midline)
/// used by the advanced player's waveform section.
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
