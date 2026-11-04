import UIKit
import AudioEngine
import AVFoundation
import Models

/// Orchestrates sharing from the session detail screen: PDF reports, the
/// full session recording, and individual event clips (shared directly when
/// a clip file exists, exported from the session recording otherwise).
/// Owns the export progress flags so the views stay presentational.
@MainActor
@Observable
final class SessionShareCoordinator {
  private(set) var isGeneratingPDF = false
  private(set) var isExportingEvent = false

  func exportReport(for session: SleepSession) {
    Task {
      isGeneratingPDF = true
      defer { isGeneratingPDF = false }
      if let url = SleepReportPDFGenerator().generatePDF(for: session) {
        presentShareSheet(items: [url])
      }
    }
  }

  func shareFullSession(_ session: SleepSession) {
    guard let url = AudioFileURLResolver.resolve(session.audioFileURL) else { return }
    presentShareSheet(items: [url])
  }

  func shareEvent(_ event: SnoreEvent, in session: SleepSession) {
    if let url = AudioFileURLResolver.resolve(event.audioFileURL),
       FileManager.default.fileExists(atPath: url.path) {
      presentShareSheet(items: [url])
    } else {
      Task {
        await exportAndShare(event: event, in: session)
      }
    }
  }

  // MARK: - Private

  private func exportAndShare(event: SnoreEvent, in session: SleepSession) async {
    guard let sourceURL = AudioFileURLResolver.resolve(session.audioFileURL) else { return }

    isExportingEvent = true
    defer { isExportingEvent = false }

    // Destructure Sendable fields before crossing into the extractor — a
    // SwiftData @Model class cannot be sent across isolation boundaries.
    let eventID = event.id
    let eventTimestamp = event.timestamp
    let eventSnoreDuration = event.snoreDuration
    let eventBursts = event.bursts
    let totalDuration = AVURLAsset(url: sourceURL).duration.seconds
    let result = await AudioClipExtractor.extractSingleClip(
      eventID: eventID,
      eventTimestamp: eventTimestamp,
      eventSnoreDuration: eventSnoreDuration,
      bursts: eventBursts,
      sessionURL: sourceURL,
      sessionStart: session.startDate,
      totalDuration: totalDuration,
      padding: 0,
      outputDirectory: FileManager.default.temporaryDirectory
    )
    guard let result else { return }

    // Verify the exported file exists and has content before presenting
    let clipURL = result.clipURL
    guard FileManager.default.fileExists(atPath: clipURL.path),
          let attrs = try? FileManager.default.attributesOfItem(atPath: clipURL.path),
          let fileSize = attrs[.size] as? Int, fileSize > 0 else { return }

    presentShareSheet(items: [clipURL])
  }

  private func presentShareSheet(items: [Any]) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.keyWindow?.rootViewController else { return }
    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
    rootVC.present(activityVC, animated: true)
  }
}
