import AudioEngine
import Foundation
import Testing
@testable import Env

/// `SessionRawLogWriter` in a temp folder: samples are timestamped by the
/// caller, written sorted, and carry the session's detection settings.
struct SessionRawLogWriterTests {
  private let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent("RawLogWriterTests-\(UUID().uuidString)")
  private let start = Date(timeIntervalSinceReferenceDate: 10000)

  init() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  private func metadata() -> RawLogMetadata {
    RawLogMetadata(
      sessionStart: start,
      detectionSensitivity: "high",
      detectSleepTalking: false,
      snoreInterrupterMode: "always")
  }

  private func append(_ writer: SessionRawLogWriter, at seconds: TimeInterval, db: Float) async {
    await writer.append(
      at: start.addingTimeInterval(seconds),
      db: db, peakDB: db + 10, spectralScore: 0,
      snoreConfidence: 0.5, speechConfidence: 0.2, state: .quiet)
  }

  private func read(_ filename: String) throws -> RawLog {
    try RawLog.decode(from: Data(contentsOf: directory.appendingPathComponent(filename)))
  }

  @Test func writesSortedSamplesWithCallerTimestamps() async throws {
    let writer = SessionRawLogWriter(directory: directory)
    let id = UUID()
    await writer.start(sessionID: id, metadata: metadata())
    // Appends arrive out of order, as unstructured tasks can deliver them.
    await append(writer, at: 0.10, db: -40)
    await append(writer, at: 0.05, db: -50)

    let filename = try #require(await writer.stop())
    let log = try read(filename)

    #expect(filename == "rawlog_\(id.uuidString).json")
    #expect(log.metadata == metadata())
    #expect(log.samples.map(\.db) == [-50, -40])
    #expect(abs(log.samples[0].elapsed - 0.05) < 1e-6)
    #expect(abs(log.samples[1].elapsed - 0.10) < 1e-6)
    #expect(log.samples[0].peakDB == -40)
    #expect(log.samples[0].speechConfidence == 0.2)
  }

  @Test func stopWithoutSamplesWritesNothing() async {
    let writer = SessionRawLogWriter(directory: directory)
    await writer.start(sessionID: UUID(), metadata: metadata())

    #expect(await writer.stop() == nil)
  }

  @Test func appendBeforeStartIsIgnored() async {
    let writer = SessionRawLogWriter(directory: directory)
    await append(writer, at: 1, db: -40)
    await writer.start(sessionID: UUID(), metadata: metadata())

    #expect(await writer.stop() == nil)
  }
}
