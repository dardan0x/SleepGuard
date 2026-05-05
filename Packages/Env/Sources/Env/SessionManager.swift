import Foundation
import Observation
import Models
import AudioEngine

@MainActor
@Observable
public final class SessionManager {
  public static let shared = SessionManager()

  public var currentSession: SleepSession?
  public var isRecording = false

  private let audioRecorder = AudioRecorder.shared
  private let snoreDetector = SnoreDetector.shared

  private init() {
    // Observation of audioRecorder and snoreDetector will be done in views
  }

  public func startSession() throws {
    let session = SleepSession(startDate: Date())
    currentSession = session
    try audioRecorder.startRecording()
    isRecording = true
  }

  public func stopSession() -> SleepSession? {
    audioRecorder.stopRecording()
    isRecording = false

    guard let session = currentSession else { return nil }
    session.endDate = Date()
    if let start = session.endDate {
      session.totalDuration = start.timeIntervalSince(session.startDate)
    }
    currentSession = nil
    return session
  }

  public func computeSleepScore(session: SleepSession) -> Int {
    let snoringPenalty = min(Int(session.snoringPercentage * 0.5), 30)
    let eventsPenalty = min(Int(session.eventsPerHour * 2), 30)
    let score = max(0, 100 - snoringPenalty - eventsPenalty)
    return score
  }
}
