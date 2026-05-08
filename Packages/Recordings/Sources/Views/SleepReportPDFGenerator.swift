import UIKit
import AudioEngine
import Models

@MainActor
public struct SleepReportPDFGenerator {
  public init() {}

  public func generatePDF(for session: SleepSession) -> URL? {
    let pageWidth: CGFloat = 612
    let pageHeight: CGFloat = 792
    let margin: CGFloat = 48

    let format = UIGraphicsPDFRendererFormat()
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

    let tempDir = FileManager.default.temporaryDirectory
    let pdfURL = tempDir.appendingPathComponent("sleep_report_\(session.id.uuidString).pdf")
    if FileManager.default.fileExists(atPath: pdfURL.path) {
      try? FileManager.default.removeItem(at: pdfURL)
    }

    do {
      try renderer.writePDF(to: pdfURL) { context in
        context.beginPage()
        var y: CGFloat = margin

        // Title
        y += drawTitle("Sleep Report", at: y, pageWidth: pageWidth, margin: margin)
        y += 8

        // Date
        y += drawDate(session.startDate, at: y, margin: margin)
        y += 24

        // Score
        y += drawScore(session.sleepScore, at: y, pageWidth: pageWidth, margin: margin)
        y += 32

        // Stats
        y += drawStats(session: session, at: y, pageWidth: pageWidth, margin: margin)
        y += 32

        // Events header
        if let events = session.events, !events.isEmpty {
          y += drawEventsHeader(at: y, margin: margin)
          y += 16

          for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            if y > pageHeight - margin - 30 {
              context.beginPage()
              y = margin
            }
            y += drawEventRow(event, at: y, margin: margin)
          }
        }
      }
      return pdfURL
    } catch {
      return nil
    }
  }

  // MARK: - Drawing Helpers

  private func drawTitle(_ text: String, at y: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 28, weight: .bold),
      .foregroundColor: UIColor.label,
    ]
    let size = text.size(withAttributes: attributes)
    text.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
    return size.height
  }

  private func drawDate(_ date: Date, at y: CGFloat, margin: CGFloat) -> CGFloat {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d, yyyy"
    let text = formatter.string(from: date)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14, weight: .medium),
      .foregroundColor: UIColor.secondaryLabel,
    ]
    let size = text.size(withAttributes: attributes)
    text.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
    return size.height
  }

  private func drawScore(_ score: Int, at y: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
    let labelAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: UIColor.secondaryLabel,
    ]
    let label = "SLEEP SCORE"
    label.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)

    let scoreAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 48, weight: .bold),
      .foregroundColor: scoreColor(score),
    ]
    let scoreText = "\(score)"
    let scoreSize = scoreText.size(withAttributes: scoreAttributes)
    scoreText.draw(at: CGPoint(x: margin, y: y + 16), withAttributes: scoreAttributes)

    let ratingAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14, weight: .medium),
      .foregroundColor: scoreColor(score),
    ]
    let ratingText = scoreRating(score)
    ratingText.draw(at: CGPoint(x: margin + scoreSize.width + 12, y: y + 36), withAttributes: ratingAttributes)

    return 16 + scoreSize.height
  }

  private func drawStats(session: SleepSession, at y: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
    let colWidth = (pageWidth - margin * 2) / 2
    let rowHeight: CGFloat = 48

    let stats: [(label: String, value: String)] = [
      ("Duration", durationString(session.totalDuration)),
      ("Snoring", String(format: "%.0f%%", session.snoringPercentage)),
      ("Events", "\(session.eventsCount)"),

      ("Events/Hour", String(format: "%.1f", session.eventsPerHour)),
    ]

    for (index, stat) in stats.enumerated() {
      let col = index % 2
      let row = index / 2
      let x = margin + CGFloat(col) * colWidth
      let rowY = y + CGFloat(row) * rowHeight

      let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: UIColor.secondaryLabel,
      ]
      stat.label.draw(at: CGPoint(x: x, y: rowY), withAttributes: labelAttributes)

      let valueAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: UIColor.label,
      ]
      stat.value.draw(at: CGPoint(x: x, y: rowY + 16), withAttributes: valueAttributes)
    }

    return CGFloat((stats.count + 1) / 2) * rowHeight
  }

  private func drawEventsHeader(at y: CGFloat, margin: CGFloat) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: UIColor.secondaryLabel,
    ]
    let text = "SNORe EVENTS"
    text.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
    return text.size(withAttributes: attributes).height
  }

  private func drawEventRow(_ event: SnoreEvent, at y: CGFloat, margin: CGFloat) -> CGFloat {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    let timeText = formatter.string(from: event.timestamp)
    let durationText = durationString(event.duration)
    let intensityText = event.intensity.rawValue.capitalized

    let rowHeight: CGFloat = 28

    // Time
    let timeAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
      .foregroundColor: UIColor.label,
    ]
    timeText.draw(at: CGPoint(x: margin, y: y), withAttributes: timeAttributes)

    // Duration
    let durationAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
      .foregroundColor: UIColor.secondaryLabel,
    ]
    durationText.draw(at: CGPoint(x: margin + 80, y: y), withAttributes: durationAttributes)

    // Intensity
    let intensityAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 13, weight: .medium),
      .foregroundColor: intensityColor(event.intensity),
    ]
    intensityText.draw(at: CGPoint(x: margin + 160, y: y), withAttributes: intensityAttributes)

    return rowHeight
  }

  // MARK: - Helpers

  private func scoreColor(_ score: Int) -> UIColor {
    switch score {
    case 80...100: return UIColor(red: 0.188, green: 0.82, blue: 0.345, alpha: 1)
    case 50..<80: return UIColor(red: 1, green: 0.624, blue: 0.039, alpha: 1)
    default: return UIColor(red: 1, green: 0.271, blue: 0.227, alpha: 1)
    }
  }

  private func scoreRating(_ score: Int) -> String {
    switch score {
    case 80...100: return "Excellent"
    case 50..<80: return "Fair"
    default: return "Poor"
    }
  }

  private func intensityColor(_ intensity: SnoreIntensity) -> UIColor {
    switch intensity {
    case .quiet: return UIColor.systemGray
    case .light: return UIColor(red: 1, green: 0.624, blue: 0.039, alpha: 1)
    case .loud: return UIColor(red: 1, green: 0.271, blue: 0.227, alpha: 1)
    }
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds % 60)
    }
    return String(format: "%d:%02d", minutes, seconds % 60)
  }
}
