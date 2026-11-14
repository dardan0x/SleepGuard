import Accelerate
import AVFoundation
import Models
import SleepCore

/// Extracts individual snore-event audio clips from a full session recording
/// and computes spectral features for each clip.
/// When an event contains burst data, the clip preserves the full event span
/// (from the first burst start to the last burst end) so breathing gaps
/// between bursts remain in the playback audio.
public enum AudioClipExtractor {
  public struct ClipResult: Sendable {
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
    outputDirectory: URL) async -> [ClipResult]
  {
    let totalDuration = await AVURLAsset(url: sessionURL).duration.seconds
    let batchSize = 4

    var results: [ClipResult] = []
    var index = events.startIndex

    while index < events.endIndex {
      let endIndex = events.index(index, offsetBy: batchSize, limitedBy: events.endIndex) ?? events.endIndex
      let batch = events[index..<endIndex]

      let batchResults = await withTaskGroup(of: ClipResult?.self) { group in
        for event in batch {
          let eventID = event.id
          let eventTimestamp = event.timestamp
          let eventSnoreDuration = event.snoreDuration
          let eventBursts = event.bursts
          group.addTask {
            await extractSingleClip(
              eventID: eventID,
              eventTimestamp: eventTimestamp,
              eventSnoreDuration: eventSnoreDuration,
              bursts: eventBursts,
              sessionURL: sessionURL,
              sessionStart: sessionStart,
              totalDuration: totalDuration,
              padding: padding,
              outputDirectory: outputDirectory)
          }
        }

        var batchResults: [ClipResult] = []
        for await result in group {
          if let result {
            batchResults.append(result)
          }
        }
        return batchResults
      }

      results.append(contentsOf: batchResults)
      index = endIndex
    }

    return results
  }

  public static func extractSingleClip(
    eventID: UUID,
    eventTimestamp: Date,
    eventSnoreDuration: TimeInterval,
    bursts: [SnoreBurst]?,
    sessionURL: URL,
    sessionStart: Date,
    totalDuration: TimeInterval,
    padding: TimeInterval,
    outputDirectory: URL) async -> ClipResult?
  {
    let eventTime = eventTimestamp.timeIntervalSince(sessionStart)
    let clipURL = outputDirectory
      .appendingPathComponent("event_\(eventID.uuidString).m4a")

    // Remove existing file
    if FileManager.default.fileExists(atPath: clipURL.path) {
      try? FileManager.default.removeItem(at: clipURL)
    }

    let exportAsset: AVAsset
    let exportTimeRange: CMTimeRange?

    if let bursts, !bursts.isEmpty {
      // Preserve full event span including breathing gaps between bursts.
      let firstBurstStart = eventTime + bursts.first!.startOffset
      let lastBurstEnd = eventTime + bursts.last!.endOffset
      let startTime = max(0, firstBurstStart - padding)
      let endTime = min(totalDuration, lastBurstEnd + padding)
      guard endTime > startTime else { return nil }
      exportAsset = AVURLAsset(url: sessionURL)
      exportTimeRange = CMTimeRange(
        start: CMTime(seconds: startTime, preferredTimescale: 600),
        duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600))
    } else {
      // Legacy: single range export
      let startTime = max(0, eventTime - padding)
      let endTime = min(totalDuration, eventTime + eventSnoreDuration + padding)
      guard endTime > startTime else { return nil }
      exportAsset = AVURLAsset(url: sessionURL)
      exportTimeRange = CMTimeRange(
        start: CMTime(seconds: startTime, preferredTimescale: 600),
        duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600))
    }

    guard let exportSession = AVAssetExportSession(
      asset: exportAsset,
      presetName: AVAssetExportPresetAppleM4A) else { return nil }

    if let timeRange = exportTimeRange {
      exportSession.timeRange = timeRange
    }
    exportSession.outputURL = clipURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    guard exportSession.status == .completed else { return nil }

    // Analyze spectral features on the extracted clip
    let spectral = await analyzeSpectralFeatures(of: clipURL)

    return ClipResult(
      eventID: eventID,
      clipURL: clipURL,
      dominantFrequency: spectral.dominantFrequency,
      spectralCentroid: spectral.spectralCentroid,
      lowFreqRatio: spectral.lowFreqRatio)
  }

  // MARK: - Private

  public struct SpectralData {
    public let dominantFrequency: Double
    public let spectralCentroid: Double
    public let lowFreqRatio: Double
  }

  /// Extracts a single clip when the total session duration is not known in advance.
  /// Computes duration from the asset on demand.
  public static func extractSingleClip(
    for event: SnoreEvent,
    sessionURL: URL,
    sessionStart: Date,
    padding: TimeInterval = 0.0,
    outputDirectory: URL) async -> ClipResult?
  {
    let totalDuration = await AVURLAsset(url: sessionURL).duration.seconds
    return await extractSingleClip(
      eventID: event.id,
      eventTimestamp: event.timestamp,
      eventSnoreDuration: event.snoreDuration,
      bursts: event.bursts,
      sessionURL: sessionURL,
      sessionStart: sessionStart,
      totalDuration: totalDuration,
      padding: padding,
      outputDirectory: outputDirectory)
  }

  public static func analyzeSpectralFeatures(of url: URL) async -> SpectralData {
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
      lowFreqRatio: lowFreqRatios.reduce(0, +) / Double(count))
  }
}
