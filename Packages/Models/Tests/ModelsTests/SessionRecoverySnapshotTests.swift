import Foundation
import ModelsTestSupport
import SleepCore
import Testing
@testable import Models

/// Crash recovery: a live (detached) session → snapshot → JSON on disk →
/// rebuilt session must match what the user would have saved.
@MainActor
struct SessionRecoverySnapshotTests {
  private let start = TestCalendar.date(day: 1, hour: 23)
  private let checkpoint = TestCalendar.date(day: 2, hour: 3)

  /// Detached, like the in-progress session during recording.
  private func liveSession(endDate: Date? = nil) -> SleepSession {
    let session = SleepSession(
      startDate: start, endDate: endDate, averageDB: -42, peakDB: -12,
      audioFileURL: "a.m4a", rawAudioFileURL: "raw.caf", rawLogFileURL: "log.json")
    session.recordingGaps = [RecordingGap(startOffset: 600, duration: 120, snoringResumed: false)]
    session.terminationReason = "low_battery"
    session.events = [
      SnoreEvent(
        timestamp: start.addingTimeInterval(300), category: .snoring, intensity: .loud,
        averageDB: -30, peakDB: -15, dominantFrequency: 120, spectralCentroid: 400, lowFreqRatio: 0.7,
        averageConfidence: 0.8, averageSpectralScore: 0.6, audioFileURL: "e1.m4a",
        bursts: [SnoreBurst(startOffset: 0, endOffset: 12)], duration: 40),
      .fixture(at: start.addingTimeInterval(5000), duration: 20, category: .sleepTalking),
    ]
    return session
  }

  private func roundTrip(_ snapshot: SessionRecoverySnapshot) throws -> SessionRecoverySnapshot {
    try JSONDecoder().decode(SessionRecoverySnapshot.self, from: JSONEncoder().encode(snapshot))
  }

  @Test func rebuiltSessionMatchesTheLiveSession() throws {
    let live = liveSession()
    let rebuilt = try roundTrip(SessionRecoverySnapshot(from: live, checkpointDate: checkpoint)).makeSession()

    #expect(rebuilt.id == live.id)
    #expect(rebuilt.startDate == start)
    #expect(rebuilt.endDate == checkpoint)
    #expect(rebuilt.averageDB == -42)
    #expect(rebuilt.peakDB == -12)
    #expect(rebuilt.audioFileURL == "a.m4a")
    #expect(rebuilt.rawAudioFileURL == "raw.caf")
    #expect(rebuilt.rawLogFileURL == "log.json")
    #expect(rebuilt.terminationReason == "low_battery")
    #expect(rebuilt.recordingGaps?.first?.duration == 120)
    #expect(rebuilt.recordingGaps?.first?.snoringResumed == false)
  }

  @Test func rebuiltEventsKeepEveryFieldAndPointBackToTheSession() throws {
    let live = liveSession()
    let rebuilt = try roundTrip(SessionRecoverySnapshot(from: live, checkpointDate: checkpoint)).makeSession()
    let original = try #require(live.events?.first { $0.category == .snoring })
    let event = try #require(rebuilt.events?.first { $0.id == original.id })

    #expect(rebuilt.events?.count == 2)
    #expect(event.session === rebuilt)
    #expect(event.timestamp == original.timestamp)
    #expect(event.intensity == .loud)
    #expect(event.averageDB == -30)
    #expect(event.peakDB == -15)
    #expect(event.dominantFrequency == 120)
    #expect(event.spectralCentroid == 400)
    #expect(event.lowFreqRatio == 0.7)
    #expect(event.averageConfidence == 0.8)
    #expect(event.averageSpectralScore == 0.6)
    #expect(event.audioFileURL == "e1.m4a")
    #expect(event.duration == 40)
    #expect(event.bursts?.first?.endOffset == 12)
  }

  @Test func rebuiltSessionScoresLikeTheLiveSession() throws {
    let live = liveSession(endDate: checkpoint)
    let rebuilt = try roundTrip(SessionRecoverySnapshot(from: live, checkpointDate: checkpoint)).makeSession()
    #expect(rebuilt.sleepScore(using: .default) == live.sleepScore(using: .default))
    #expect(rebuilt.snoringDuration == live.snoringDuration)
  }

  @Test func existingEndDateWinsOverCheckpointDate() {
    let ended = TestCalendar.date(day: 2, hour: 6)
    let snapshot = SessionRecoverySnapshot(from: liveSession(endDate: ended), checkpointDate: checkpoint)
    #expect(snapshot.lastCheckpointDate == ended)
  }

  @Test func sessionWithoutEventsIsNotRecoverable() {
    let session = SleepSession(startDate: start)
    #expect(!SessionRecoverySnapshot(from: session, checkpointDate: checkpoint).isRecoverable)
    #expect(SessionRecoverySnapshot(from: liveSession(), checkpointDate: checkpoint).isRecoverable)
  }
}
