import AVFoundation
import Testing
@testable import AudioEngine

/// Raw per-event .caf → small mono AAC .m4a.
struct EventClipCompressorTests {
  private let folder: TempFolder
  private let source: URL
  private let destination: URL

  init() throws {
    folder = try TempFolder()
    source = folder.url.appendingPathComponent("event.caf")
    destination = folder.url.appendingPathComponent("event.m4a")
    try TestAudio.writeTone(to: source, seconds: 5)
  }

  @Test func compressesToSmallerMonoAACWithTheSameDuration() async throws {
    #expect(await EventClipCompressor.compress(from: source, to: destination))

    let file = try AVAudioFile(forReading: destination)
    #expect(file.fileFormat.channelCount == 1)
    #expect(file.fileFormat.sampleRate >= 16000)
    let formatID = file.fileFormat.streamDescription.pointee.mFormatID
    #expect([kAudioFormatMPEG4AAC_HE, kAudioFormatMPEG4AAC].contains(formatID))

    #expect(try await abs(TestAudio.duration(of: destination) - 5) < 0.15)
    let sourceSize = try #require(try FileManager.default.attributesOfItem(atPath: source.path)[.size] as? Int)
    let outputSize = try #require(try FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? Int)
    #expect(outputSize * 20 < sourceSize) // float32 PCM ≈ 1.4 Mbps vs. ≤ 24 kbps
  }

  @Test func replacesAnExistingDestination() async throws {
    try Data("stale".utf8).write(to: destination)
    #expect(await EventClipCompressor.compress(from: source, to: destination))
    #expect(try await abs(TestAudio.duration(of: destination) - 5) < 0.15)
  }

  @Test func missingSourceFails() async {
    let missing = folder.url.appendingPathComponent("missing.caf")
    #expect(await !EventClipCompressor.compress(from: missing, to: destination))
  }
}
