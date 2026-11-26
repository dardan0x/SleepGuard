import AudioEngine
import AVFoundation
import Models
import SleepAudioKit
import UIKit

/// Orchestrates sharing from the session detail screen: PDF reports, the
/// full session recording, and individual event clips (shared directly when
/// a clip file exists, exported from the session recording otherwise).
/// Owns the export progress flags so the views stay presentational.
@MainActor
@Observable
final class SessionShareCoordinator {
  private(set) var isGeneratingPDF = false
  private(set) var isExportingEvent = false

  /// Shares the report `write` makes (the view draws it: the shared
  /// `NightReportPDF`), showing progress meanwhile.
  func exportReport(_ write: @escaping @MainActor () throws -> URL) {
    Task {
      isGeneratingPDF = true
      defer { isGeneratingPDF = false }
      await Task.yield()
      do {
        try presentShareSheet(items: [write()])
      } catch {
        Log.playback.error("PDF report failed: \(String(describing: error), privacy: .public)")
      }
    }
  }

  func shareFullSession(_ session: NightRecord) {
    guard let url = AudioFileURLResolver.resolve(session.rawAudioFileName) else { return }
    presentShareSheet(items: [url])
  }

  func shareEvent(_ event: NightEventRecord, in session: NightRecord) {
    if let url = AudioFileURLResolver.resolve(event.clipFileName),
       FileManager.default.fileExists(atPath: url.path)
    {
      presentShareSheet(items: [url])
    } else {
      Task {
        await exportAndShare(event: event, in: session)
      }
    }
  }

  // MARK: - Private

  private func exportAndShare(event: NightEventRecord, in session: NightRecord) async {
    guard let sourceURL = AudioFileURLResolver.resolve(session.rawAudioFileName) else { return }

    isExportingEvent = true
    defer { isExportingEvent = false }

    // The event's Sendable fields, read here: a SwiftData @Model can't cross
    // into the extractor.
    let clipURL = FileManager.default.temporaryDirectory.appendingPathComponent("event_\(event.id.uuidString).m4a")
    guard await ClipExtractor.extract(event.clipSource, from: sourceURL, nightStart: session.start, to: clipURL)
    else { return }

    // Verify the exported file exists and has content before presenting
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
