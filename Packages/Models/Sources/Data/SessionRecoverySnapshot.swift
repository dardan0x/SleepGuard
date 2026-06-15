import Foundation

/// A `Codable` snapshot of an in-progress `SleepSession` and its events,
/// written to disk during recording so a session can be reconstructed after a
/// crash / OOM / background termination. `@Model` types can't be `Codable`
/// directly, so this plain struct mirrors their persistable fields.
///
/// The session itself never enters the database until the user explicitly saves
/// it — on next launch the snapshot rebuilds an in-memory `SleepSession` that is
/// surfaced through the normal summary screen for Save or Discard.
public struct SessionRecoverySnapshot: Codable, Sendable {
  public struct EventSnapshot: Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let category: SoundCategory
    public let intensity: SnoreIntensity
    public let averageDB: Double
    public let peakDB: Double
    public let dominantFrequency: Double
    public let spectralCentroid: Double
    public let lowFreqRatio: Double
    public let averageConfidence: Double
    public let averageSpectralScore: Double
    public let audioFileURL: String?
    public let duration: TimeInterval
    public let bursts: [SnoreBurst]?

    public init(from event: SnoreEvent) {
      self.id = event.id
      self.timestamp = event.timestamp
      self.category = event.category
      self.intensity = event.intensity
      self.averageDB = event.averageDB
      self.peakDB = event.peakDB
      self.dominantFrequency = event.dominantFrequency
      self.spectralCentroid = event.spectralCentroid
      self.lowFreqRatio = event.lowFreqRatio
      self.averageConfidence = event.averageConfidence
      self.averageSpectralScore = event.averageSpectralScore
      self.audioFileURL = event.audioFileURL
      self.duration = event.duration
      self.bursts = event.bursts
    }

    public func makeEvent() -> SnoreEvent {
      SnoreEvent(
        id: id,
        timestamp: timestamp,
        category: category,
        intensity: intensity,
        averageDB: averageDB,
        peakDB: peakDB,
        dominantFrequency: dominantFrequency,
        spectralCentroid: spectralCentroid,
        lowFreqRatio: lowFreqRatio,
        averageConfidence: averageConfidence,
        averageSpectralScore: averageSpectralScore,
        audioFileURL: audioFileURL,
        bursts: bursts,
        duration: duration
      )
    }
  }

  public let id: UUID
  public let startDate: Date
  /// Time of the last checkpoint write; becomes the recovered session's `endDate`.
  public let lastCheckpointDate: Date
  public let averageDB: Double
  public let peakDB: Double
  public let audioFileURL: String?
  public let rawAudioFileURL: String?
  public let rawLogFileURL: String?
  public let recordingGaps: [RecordingGap]?
  public let terminationReason: String?
  public let events: [EventSnapshot]

  public init(from session: SleepSession, checkpointDate: Date) {
    self.id = session.id
    self.startDate = session.startDate
    self.lastCheckpointDate = session.endDate ?? checkpointDate
    self.averageDB = session.averageDB
    self.peakDB = session.peakDB
    self.audioFileURL = session.audioFileURL
    self.rawAudioFileURL = session.rawAudioFileURL
    self.rawLogFileURL = session.rawLogFileURL
    self.recordingGaps = session.recordingGaps
    self.terminationReason = session.terminationReason
    self.events = (session.events ?? []).map(EventSnapshot.init(from:))
  }

  /// Whether this snapshot holds anything worth recovering. Empty sessions
  /// (no detected events) are discarded silently rather than prompting the user.
  public var isRecoverable: Bool {
    !events.isEmpty
  }

  /// Rebuilds an in-memory `SleepSession` with its events wired up. The returned
  /// session is detached (not in any `ModelContext`) — identical to the object
  /// the live flow hands to the summary screen.
  public func makeSession() -> SleepSession {
    let session = SleepSession(
      startDate: startDate,
      endDate: lastCheckpointDate,
      averageDB: averageDB,
      peakDB: peakDB,
      audioFileURL: audioFileURL,
      rawAudioFileURL: rawAudioFileURL,
      rawLogFileURL: rawLogFileURL
    )
    session.id = id
    session.recordingGaps = recordingGaps
    session.terminationReason = terminationReason

    let rebuilt = events.map { $0.makeEvent() }
    for event in rebuilt {
      event.session = session
    }
    session.events = rebuilt
    return session
  }
}
