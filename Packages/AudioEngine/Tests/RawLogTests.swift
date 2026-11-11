import Foundation
import Testing
@testable import AudioEngine

/// Raw log formats: 3 (JSON Lines, F23-T9) and 2 (`RawLog` object) round-trip,
/// format 1 (bare sample array, before F22-T1) still decodes, and a format-3
/// log cut short by a crash keeps everything before the partial line.
struct RawLogTests {
  @Test func formatTwoRoundTrips() throws {
    let log = RawLog(
      metadata: RawLogMetadata(
        formatVersion: 2,
        sessionStart: Date(timeIntervalSinceReferenceDate: 1000),
        detectionSensitivity: "medium",
        detectSleepTalking: true,
        snoreInterrupterMode: "never"),
      samples: [
        SnoreSample(
          elapsed: 0.05, db: -48, peakDB: -31, spectralScore: 0.2,
          snoreConfidence: 0.7, speechConfidence: 0.1, state: .light),
      ])

    let decoded = try RawLog.decode(from: JSONEncoder().encode(log))

    #expect(decoded == log)
    #expect(decoded.metadata?.formatVersion == 2)
  }

  private static let metadata = RawLogMetadata(
    sessionStart: Date(timeIntervalSinceReferenceDate: 1000),
    detectionSensitivity: "high",
    detectSleepTalking: false,
    snoreInterrupterMode: "always")

  private static func sample(_ elapsed: TimeInterval) -> SnoreSample {
    SnoreSample(elapsed: elapsed, db: -40, peakDB: -30, spectralScore: 0, snoreConfidence: 0.5, speechConfidence: 0, state: .quiet)
  }

  @Test func formatThreeRoundTripsSorted() throws {
    var data = try RawLog.line(Self.metadata)
    // Chunks are appended in roughly arrival order; the reader sorts.
    for elapsed in [0.10, 0.05, 0.15] {
      try data.append(RawLog.line(Self.sample(elapsed)))
    }

    let log = try RawLog.decode(from: data)

    #expect(log.metadata == Self.metadata)
    #expect(log.metadata?.formatVersion == 3)
    #expect(log.samples.map(\.elapsed) == [0.05, 0.10, 0.15])
  }

  @Test func formatThreeCutShortByACrashKeepsCompleteLines() throws {
    var data = try RawLog.line(Self.metadata)
    try data.append(RawLog.line(Self.sample(0.05)))
    try data.append(RawLog.line(Self.sample(0.10)))
    let partial = try RawLog.line(Self.sample(0.15))
    data.append(partial.prefix(partial.count / 2))

    let log = try RawLog.decode(from: data)

    #expect(log.samples.map(\.elapsed) == [0.05, 0.10])
  }

  @Test func formatThreeRejectsACorruptLineInTheMiddle() throws {
    var data = try RawLog.line(Self.metadata)
    data.append(Data("{not json}\n".utf8))
    try data.append(RawLog.line(Self.sample(0.10)))

    #expect(throws: DecodingError.self) { try RawLog.decode(from: data) }
  }

  @Test func formatOneDecodesWithoutNewFields() throws {
    let json = """
    [{"elapsed":0.05,"db":-48,"spectralScore":0,"snoreConfidence":0.6,"state":"quiet"}]
    """

    let log = try RawLog.decode(from: Data(json.utf8))

    #expect(log.metadata == nil)
    #expect(log.samples.count == 1)
    #expect(log.samples[0].snoreConfidence == 0.6)
    #expect(log.samples[0].peakDB == nil)
    #expect(log.samples[0].speechConfidence == nil)
  }

  @Test func garbageThrows() {
    #expect(throws: (any Error).self) {
      try RawLog.decode(from: Data("{}".utf8))
    }
  }
}
