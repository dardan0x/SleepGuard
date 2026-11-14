import AVFoundation
import Models
import SleepCore
import Testing
@testable import AudioEngine

/// Clip extraction from a 10 s, 215 Hz session file. AAC encoding adds a few
/// tens of milliseconds, so durations are checked to ±0.15 s.
struct AudioClipExtractorTests {
  private let folder: TempFolder
  private let sessionURL: URL
  private let sessionStart = Date(timeIntervalSinceReferenceDate: 0)

  init() throws {
    folder = try TempFolder()
    sessionURL = folder.url.appendingPathComponent("session.caf")
    try TestAudio.writeTone(to: sessionURL, seconds: 10)
  }

  private func clip(
    at offset: TimeInterval,
    duration: TimeInterval = 0,
    bursts: [SnoreBurst]? = nil,
    padding: TimeInterval = 0) async -> AudioClipExtractor.ClipResult?
  {
    await AudioClipExtractor.extractSingleClip(
      eventID: UUID(),
      eventTimestamp: sessionStart.addingTimeInterval(offset),
      eventSnoreDuration: duration,
      bursts: bursts,
      sessionURL: sessionURL,
      sessionStart: sessionStart,
      totalDuration: 10,
      padding: padding,
      outputDirectory: folder.url)
  }

  @Test func eventWithoutBurstsSpansItsDurationPlusPadding() async throws {
    // 2 s + 3 s event, 0.5 s padding → 1.5…5.5 s
    let result = try #require(await clip(at: 2, duration: 3, padding: 0.5))
    #expect(try await abs(TestAudio.duration(of: result.clipURL) - 4) < 0.15)
    #expect(result.clipURL.lastPathComponent == "event_\(result.eventID.uuidString).m4a")
  }

  @Test func burstsSetTheSpanAndIgnoreTheEventDuration() async throws {
    // First burst starts 0.5 s in, last ends 3.5 s in → 2.5…5.5 s
    let bursts = [SnoreBurst(startOffset: 0.5, endOffset: 1), SnoreBurst(startOffset: 3, endOffset: 3.5)]
    let result = try #require(await clip(at: 2, duration: 99, bursts: bursts))
    #expect(try await abs(TestAudio.duration(of: result.clipURL) - 3) < 0.15)
  }

  @Test func paddingIsClampedToTheFile() async throws {
    // 0.5 s − 2 s padding → 0; 9 s + 0.5 s + 2 s → 10 s
    let result = try #require(await clip(at: 0.5, duration: 9, padding: 2))
    #expect(try await abs(TestAudio.duration(of: result.clipURL) - 10) < 0.15)
  }

  @Test func eventPastTheEndOfTheFileGivesNoClip() async {
    #expect(await clip(at: 12, duration: 3) == nil)
  }

  @Test func clipFeaturesDescribeTheTone() async throws {
    let result = try #require(await clip(at: 2, duration: 3))
    #expect(abs(result.dominantFrequency - 215) < 43)
    #expect(result.lowFreqRatio > 0.8)
    #expect(result.spectralCentroid < 400)
  }

  @Test func existingClipIsReplaced() async throws {
    let id = UUID()
    let url = folder.url.appendingPathComponent("event_\(id.uuidString).m4a")
    try Data("stale".utf8).write(to: url)
    let result = await AudioClipExtractor.extractSingleClip(
      eventID: id, eventTimestamp: sessionStart.addingTimeInterval(1), eventSnoreDuration: 2, bursts: nil,
      sessionURL: sessionURL, sessionStart: sessionStart, totalDuration: 10, padding: 0, outputDirectory: folder.url)
    #expect(result != nil)
    #expect(try await abs(TestAudio.duration(of: url) - 2) < 0.15)
  }

  @Test func extractClipsHandlesMoreEventsThanOneBatch() async {
    // Batches of 4: six events need two batches; the out-of-range one is skipped.
    let events = (0..<6).map { SnoreEvent(timestamp: sessionStart.addingTimeInterval(Double($0)), intensity: .light, averageDB: -30, peakDB: -20, duration: 1) }
    let outOfRange = SnoreEvent(timestamp: sessionStart.addingTimeInterval(30), intensity: .light, averageDB: -30, peakDB: -20, duration: 1)
    let results = await AudioClipExtractor.extractClips(
      from: sessionURL, events: events + [outOfRange], sessionStart: sessionStart, outputDirectory: folder.url)
    #expect(Set(results.map(\.eventID)) == Set(events.map(\.id)))
  }

  @Test func missingFileHasNoSpectralFeatures() async {
    let data = await AudioClipExtractor.analyzeSpectralFeatures(of: folder.url.appendingPathComponent("missing.m4a"))
    #expect(data.dominantFrequency == 0)
    #expect(data.lowFreqRatio == 0)
  }
}
