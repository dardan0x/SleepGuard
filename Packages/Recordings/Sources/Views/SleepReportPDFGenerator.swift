import UIKit
import AudioEngine
import Models
import DesignSystem

@MainActor
public struct SleepReportPDFGenerator {
  public init() {}

  // Design tokens
  private let pageWidth: CGFloat = 612
  private let pageHeight: CGFloat = 792
  private let margin: CGFloat = 40
  private let gradientTop = UIColor(red: 0.50, green: 0.85, blue: 0.95, alpha: 1)
  private let gradientMid = UIColor(red: 0.10, green: 0.45, blue: 0.75, alpha: 1.0)
  private let gradientBottom = UIColor(red: 0.05, green: 0.15, blue: 0.40, alpha: 1.0)
  private let pageBg = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
  private let cardBg = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1)
  private let rowBg = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1)
  private let textPrimary = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
  private let textSecondary = UIColor(red: 0.45, green: 0.50, blue: 0.58, alpha: 1)
  private let quietColor = UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
  private let lightColor = UIColor(red: 1, green: 0.624, blue: 0.039, alpha: 1)
  private let loudColor = UIColor(red: 1, green: 0.271, blue: 0.227, alpha: 1)

  public func generatePDF(for session: SleepSession) -> URL? {
    let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
      ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
      ?? "SnoreGuard"
    let reportTitle = "\(appName) Sleep Report"

    let format = UIGraphicsPDFRendererFormat()
    let renderer = UIGraphicsPDFRenderer(
      bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
      format: format
    )

    let tempDir = FileManager.default.temporaryDirectory
    let pdfURL = tempDir.appendingPathComponent("sleep_report_\(session.id.uuidString).pdf")
    if FileManager.default.fileExists(atPath: pdfURL.path) {
      try? FileManager.default.removeItem(at: pdfURL)
    }

    do {
      // Force light mode trait collection so colors render exactly as defined
      // and are not shifted by device dark mode
      let lightTraits = UITraitCollection(userInterfaceStyle: .light)
      let previousTraits = UITraitCollection.current
      UITraitCollection.current = lightTraits
      defer { UITraitCollection.current = previousTraits }

      try renderer.writePDF(to: pdfURL) { context in
        context.beginPage()
        let cgContext = context.cgContext

        // White page background (prevents dark mode viewers from showing dark bg)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        pageBg.setFill()
        UIRectFill(pageRect)

        var y: CGFloat = 0

        // Header banner with blue gradient
        y += drawHeader(session: session, title: reportTitle, context: cgContext)
        y += 32

        // Score card
        y += drawScoreCard(score: session.sleepScore, at: y)
        y += 32

        // Stats grid
        y += drawStatsGrid(session: session, at: y)
        y += 32

        // Events section
        if let events = session.events, !events.isEmpty {
          y += drawEventsSection(events: events, at: y, context: context, pageHeight: pageHeight)
        }

        // Footer
        drawFooter(at: pageHeight - margin)
      }
      return pdfURL
    } catch {
      return nil
    }
  }

  // MARK: - Header

  private func drawHeader(session: SleepSession, title: String, context: CGContext) -> CGFloat {
    let headerHeight: CGFloat = 140
    let bannerRect = CGRect(x: 0, y: 0, width: pageWidth, height: headerHeight)

    // Red gradient background
    let gradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: [
        gradientTop.cgColor,
        gradientMid.cgColor,
        gradientBottom.cgColor
      ] as CFArray,
      locations: [0, 0.5, 1]
    )!
    context.drawLinearGradient(
      gradient,
      start: CGPoint(x: 0, y: 0),
      end: CGPoint(x: pageWidth, y: headerHeight),
      options: []
    )

    // Title
    let titleAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 32, weight: .bold),
      .foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
    ]
    title.draw(at: CGPoint(x: margin, y: 44), withAttributes: titleAttrs)

    // Date
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d, yyyy"
    let dateText = formatter.string(from: session.startDate)
    let dateAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14, weight: .medium),
      .foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.85),
    ]
    dateText.draw(at: CGPoint(x: margin, y: 84), withAttributes: dateAttrs)

    // Decorative circle
    let circlePath = UIBezierPath(
      arcCenter: CGPoint(x: pageWidth - 60, y: 70),
      radius: 40,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    UIColor(red: 1, green: 1, blue: 1, alpha: 0.15).setFill()
    circlePath.fill()

    // Small inner circle
    let innerPath = UIBezierPath(
      arcCenter: CGPoint(x: pageWidth - 60, y: 70),
      radius: 24,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    UIColor(red: 1, green: 1, blue: 1, alpha: 0.25).setFill()
    innerPath.fill()

    return headerHeight
  }

  // MARK: - Score Card

  private func drawScoreCard(score: Int, at y: CGFloat) -> CGFloat {
    let cardHeight: CGFloat = 140
    let cardRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: cardHeight)

    // Card background
    let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
    cardBg.setFill()
    cardPath.fill()

    // Score circle
    let circleRadius: CGFloat = 44
    let circleCenter = CGPoint(x: margin + 60, y: y + cardHeight / 2)
    let circlePath = UIBezierPath(
      arcCenter: circleCenter,
      radius: circleRadius,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    scoreColor(score).withAlphaComponent(0.15).setFill()
    circlePath.fill()

    // Score number
    let scoreAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 36, weight: .bold),
      .foregroundColor: scoreColor(score),
    ]
    let scoreText = "\(score)"
    let scoreSize = scoreText.size(withAttributes: scoreAttrs)
    scoreText.draw(
      at: CGPoint(x: circleCenter.x - scoreSize.width / 2, y: circleCenter.y - scoreSize.height / 2 + 2),
      withAttributes: scoreAttrs
    )

    // Label
    let labelAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: textSecondary,
    ]
    "SLEEP SCORE".draw(at: CGPoint(x: margin + 120, y: y + 44), withAttributes: labelAttrs)

    // Rating
    let ratingAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 24, weight: .bold),
      .foregroundColor: scoreColor(score),
    ]
    scoreRating(score).draw(at: CGPoint(x: margin + 120, y: y + 62), withAttributes: ratingAttrs)

    // Divider line
    let linePath = UIBezierPath()
    linePath.move(to: CGPoint(x: margin + 120, y: y + 104))
    linePath.addLine(to: CGPoint(x: pageWidth - margin - 24, y: y + 104))
    UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).setStroke()
    linePath.lineWidth = 1
    linePath.stroke()

    // Subtext
    let subAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .medium),
      .foregroundColor: textSecondary,
    ]
    "Based on snoring duration & event frequency".draw(
      at: CGPoint(x: margin + 120, y: y + 112),
      withAttributes: subAttrs
    )

    return cardHeight
  }

  // MARK: - Stats Grid

    private func drawStatsGrid(session: SleepSession, at y: CGFloat) -> CGFloat {
        let stats: [(label: String, value: String, icon: String)] = [
            (Strings.recordingsPlayerStatDuration, durationString(session.totalDuration), "⏱"),
            (Strings.sessionSummaryStatSnoring, String(format: "%.0f%%", session.snoringPercentage), "📊"),
            (Strings.recordingsDetailEventsLabel, "\(session.eventsCount)", "🔔"),
            (Strings.eventsHourPdfGenerator, String(format: "%.1f", session.eventsPerHour), "📈"),
        ]

    let cardWidth = (pageWidth - margin * 2 - 16) / 2
    let cardHeight: CGFloat = 90
    var maxY = y

    for (index, stat) in stats.enumerated() {
      let col = index % 2
      let row = index / 2
      let x = margin + CGFloat(col) * (cardWidth + 16)
      let rowY = y + CGFloat(row) * (cardHeight + 16)
      let cardRect = CGRect(x: x, y: rowY, width: cardWidth, height: cardHeight)

      // Card background
      let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 16)
      cardBg.setFill()
      cardPath.fill()

      // Icon
      let iconAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 20),
      ]
      stat.icon.draw(at: CGPoint(x: x + 16, y: rowY + 16), withAttributes: iconAttrs)

      // Label
      let labelAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: textSecondary,
      ]
      stat.label.draw(at: CGPoint(x: x + 16, y: rowY + 44), withAttributes: labelAttrs)

      // Value
      let valueAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .bold),
        .foregroundColor: textPrimary,
      ]
      stat.value.draw(at: CGPoint(x: x + 16, y: rowY + 58), withAttributes: valueAttrs)

      maxY = rowY + cardHeight
    }

    return maxY - y
  }

  // MARK: - Events Section

  private func drawEventsSection(
    events: [SnoreEvent],
    at y: CGFloat,
    context: UIGraphicsPDFRendererContext,
    pageHeight: CGFloat
  ) -> CGFloat {
    var currentY = y

    // Section header
    let headerAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14, weight: .bold),
      .foregroundColor: textPrimary,
    ]
    "Snore Events".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttrs)
    currentY += 28

    // Header row
    drawEventHeader(at: currentY)
    currentY += 28

    // Divider
    let divider = UIBezierPath()
    divider.move(to: CGPoint(x: margin, y: currentY - 8))
    divider.addLine(to: CGPoint(x: pageWidth - margin, y: currentY - 8))
    UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1).setStroke()
    divider.lineWidth = 1
    divider.stroke()

    for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
      if currentY > pageHeight - margin - 50 {
        context.beginPage()
        currentY = margin + 20
      }
      currentY += drawEventRow(event, at: currentY)
    }

    return currentY - y
  }

  private func drawEventHeader(at y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
      .foregroundColor: textPrimary,
    ]
    "Time".draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
    "Duration".draw(at: CGPoint(x: margin + 100, y: y), withAttributes: attrs)
    "Intensity".draw(at: CGPoint(x: margin + 200, y: y), withAttributes: attrs)
  }

  private func drawEventRow(_ event: SnoreEvent, at y: CGFloat) -> CGFloat {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    let timeText = formatter.string(from: event.timestamp)
    let durationText = durationString(event.snoreDuration)
    let intensityText = event.intensity.rawValue.capitalized
    let color = intensityColor(event.intensity)

    let rowHeight: CGFloat = 36

    // Alternating row background
    let rowRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: rowHeight)
    let rowPath = UIBezierPath(roundedRect: rowRect, cornerRadius: 8)
    rowBg.setFill()
    rowPath.fill()

    // Color dot
    let dotPath = UIBezierPath(
      arcCenter: CGPoint(x: margin + 12, y: y + rowHeight / 2),
      radius: 5,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    color.setFill()
    dotPath.fill()

    // Time
    let timeAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
      .foregroundColor: textPrimary,
    ]
    timeText.draw(at: CGPoint(x: margin + 28, y: y + 9), withAttributes: timeAttrs)

    // Duration
    let durAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
      .foregroundColor: textSecondary,
    ]
    durationText.draw(at: CGPoint(x: margin + 100, y: y + 9), withAttributes: durAttrs)

    // Intensity with pill background
    let intensityAttrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: color,
    ]
    let intensitySize = intensityText.size(withAttributes: intensityAttrs)
    let pillRect = CGRect(
      x: margin + 200,
      y: y + 6,
      width: intensitySize.width + 20,
      height: 24
    )
    let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 12)
    color.withAlphaComponent(0.12).setFill()
    pillPath.fill()
    intensityText.draw(
      at: CGPoint(x: pillRect.midX - intensitySize.width / 2, y: pillRect.midY - intensitySize.height / 2 + 1),
      withAttributes: intensityAttrs
    )

    return rowHeight + 4
  }

  // MARK: - Footer

  private func drawFooter(at y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 10, weight: .medium),
      .foregroundColor: textSecondary.withAlphaComponent(0.7),
    ]
    let text = "Generated by SnoreGuard"
    let size = text.size(withAttributes: attrs)
    text.draw(
      at: CGPoint(x: (pageWidth - size.width) / 2, y: y),
      withAttributes: attrs
    )
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
    case .quiet: return quietColor
    case .light: return lightColor
    case .loud: return loudColor
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
