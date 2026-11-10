import Foundation
import Testing
@testable import AudioEngine

/// `rawlog_<id>.json` format: format 2 (`RawLog` object) round-trips, and
/// format 1 (bare sample array, before F22-T1) still decodes.
struct RawLogTests {
  @Test func formatTwoRoundTrips() throws {
    let log = RawLog(
      metadata: RawLogMetadata(
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
