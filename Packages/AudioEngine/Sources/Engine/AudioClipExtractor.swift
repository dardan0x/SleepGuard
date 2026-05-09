import AVFoundation
import Accelerate
import Models

/// Extracts individual snore-event audio clips from a full session recording
/// and computes spectral features for each clip.
public enum AudioClipExtractor {
  public struct ClipResult {
    public let eventID: UUID
    public let clipURL: URL
    public let dominantFrequency: Double
    public let spectralCentroid: Double
    public let lowFreqRatio: Double
  }

  /// Extracts clips for all events and computes their spectral features.
  /// - Parameters:
  ///   - sessionURL: URL of the full session audio file.
  ///   - events: Snore events to extract clips for.
  ///   - sessionStart: The session start date (used to compute event offsets).
  ///   - padding: Seconds of silence to include before/after each event.
  ///   - outputDirectory: Directory to write clip files to.
  /// - Returns: Array of results mapping each event to its clip and spectral data.
  public static func extractClips(
    from sessionURL: URL,
    events: [SnoreEvent],
    sessionStart: Date,
    padding: TimeInterval = 0.0,
    outputDirectory: URL
  ) async -> [ClipResult] {
    let asset = AVURLAsset(url: sessionURL)
    let totalDuration = await asset.duration.seconds

    var results: [ClipResult] = []

    for event in events {
      let eventTime = event.timestamp.timeIntervalSince(sessionStart)
      let startTime = max(0, eventTime - padding)
      let endTime = min(totalDuration, eventTime + event.duration + padding)
      guard endTime > startTime else { continue }

      let clipURL = outputDirectory
        .appendingPathComponent("event_\(event.id.uuidString).m4a")

      // Remove existing file
      if FileManager.default.fileExists(atPath: clipURL.path) {
        try? FileManager.default.removeItem(at: clipURL)
      }

      guard let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPresetAppleM4A
      ) else { continue }

      exportSession.timeRange = CMTimeRange(
        start: CMTime(seconds: startTime, preferredTimescale: 600),
        duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
      )
      exportSession.outputURL = clipURL
      exportSession.outputFileType = .m4a

      await exportSession.export()
      guard exportSession.status == .completed else { continue }

      // Analyze spectral features
      let spectral = await analyzeSpectralFeatures(of: clipURL)

      results.append(ClipResult(
        eventID: event.id,
        clipURL: clipURL,
        dominantFrequency: spectral.dominantFrequency,
        spectralCentroid: spectral.spectralCentroid,
        lowFreqRatio: spectral.lowFreqRatio
      ))
    }

    return results
  }

  // MARK: - Private

  private struct SpectralData {
    let dominantFrequency: Double
    let spectralCentroid: Double
    let lowFreqRatio: Double
  }

  private static func analyzeSpectralFeatures(of url: URL) async -> SpectralData {
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      return SpectralData(dominantFrequency: 0, spectralCentroid: 0, lowFreqRatio: 0)
    }

    let format = audioFile.processingFormat
    let bufferSize = 1024
    let fftAnalyzer = FFTAnalyzer(bufferSize: bufferSize)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferSize))!

    var dominantFrequencies: [Double] = []
    var spectralCentroids: [Double] = []
    var lowFreqRatios: [Double] = []

    while audioFile.framePosition < audioFile.length {
      do {
        try audioFile.read(into: buffer)
        let features = fftAnalyzer.analyze(buffer: buffer, sampleRate: format.sampleRate)
        dominantFrequencies.append(Double(features.dominantFrequency))
        spectralCentroids.append(Double(features.spectralCentroid))
        lowFreqRatios.append(Double(features.lowFreqRatio))
      } catch {
        break
      }
    }

    let count = max(dominantFrequencies.count, 1)
    return SpectralData(
      dominantFrequency: dominantFrequencies.reduce(0, +) / Double(count),
      spectralCentroid: spectralCentroids.reduce(0, +) / Double(count),
      lowFreqRatio: lowFreqRatios.reduce(0, +) / Double(count)
    )
  }
}


