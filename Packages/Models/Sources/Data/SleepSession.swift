import Foundation
import SwiftData

public enum SleepStage: String, Codable, Sendable {
  case awake
  case rem
  case light
  case deep
}

public struct SleepStageSegment: Codable, Sendable {
  public let stage: SleepStage
  public let startOffset: TimeInterval
  public let duration: TimeInterval

  public init(stage: SleepStage, startOffset: TimeInterval, duration: TimeInterval) {
    self.stage = stage
    self.startOffset = startOffset
    self.duration = duration
  }
}

/// Aggregated sleep stage percentages derived from `sleepStageSegments`.
public struct StageStats: Sendable {
  public let awakePct: Double
  public let remPct: Double
  public let lightPct: Double
  public let deepPct: Double
}

@Model
public final class SleepSession {
    @Attribute(.unique) public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
    /// Values are relative and vary by microphone sensitivity and device distance.
    public var averageDB: Double
    /// Relative loudness in dBFS (digital full scale), not calibrated dB-SPL.
    public var peakDB: Double
    public var audioFileURL: String?

    /// Full session raw audio file preserved for future re-processing.
    /// When detection thresholds or debounce logic change, old sessions
    /// can be re-analysed from this file instead of using baked event data.
    public var rawAudioFileURL: String?

    /// Classification sample log (JSON) recorded at ~20 Hz during the session.
    /// Contains every sample's dB, spectral score, snore confidence, and state.
    /// Allows instant re-processing with different debounce or threshold values
    /// without re-running audio analysis.
    public var rawLogFileURL: String?

    @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session)
    public var events: [SnoreEvent]?

    /// Intervals when the microphone was paused (e.g. during soothing melody playback).
    /// Used to compute monitoredDuration and surface detection blind spots in the UI.
    public var recordingGaps: [RecordingGap]?

    /// Why the session ended early (e.g. "low_battery"). Set when the app force-saves
    /// to preserve data before the phone shuts down. nil for normal user-stopped sessions.
    public var terminationReason: String?

    /// Optional sleep stage segments sourced from Apple Health (Apple Watch).
    /// nil when no Watch data is available for this session.
    public var sleepStageSegments: [SleepStageSegment]?

    public static let minimumSaveDuration: TimeInterval = 120

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        averageDB: Double = 0,
        peakDB: Double = 0,
        audioFileURL: String? = nil,
        rawAudioFileURL: String? = nil,
        rawLogFileURL: String? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.averageDB = averageDB
        self.peakDB = peakDB
        self.audioFileURL = audioFileURL
        self.rawAudioFileURL = rawAudioFileURL
        self.rawLogFileURL = rawLogFileURL
    }

    /// Derived from raw data. Computed on demand so formula changes retroactively affect all sessions.
    public var totalDuration: TimeInterval {
        endDate?.timeIntervalSince(startDate) ?? 0
    }

    /// Total duration of all recording gaps (microphone-paused intervals).
    public var gapsDuration: TimeInterval {
        recordingGaps?.reduce(0) { $0 + $1.duration } ?? 0
    }

    public var snoringDuration: TimeInterval {
        events?.filter { $0.category == .snoring }.reduce(0) { $0 + $1.snoreDuration } ?? 0
    }

    /// Total duration of sleep talking events.
    public var sleepTalkingDuration: TimeInterval {
        events?.filter { $0.category == .sleepTalking }.reduce(0) { $0 + $1.snoreDuration } ?? 0
    }

    /// Sleep talking events count.
    public var sleepTalkingEvents: Int {
        events?.filter { $0.category == .sleepTalking }.count ?? 0
    }

    /// Sleep talking duration as a percentage of total session time.
    public var sleepTalkingPercentage: Double {
        totalDuration > 0 ? (sleepTalkingDuration / totalDuration) * 100 : 0
    }

    /// Sleep talking events per hour.
    public var sleepTalkingEventsPerHour: Double {
        totalDuration > 0 ? Double(sleepTalkingEvents) / (totalDuration / 3600) : 0
    }

    /// Total duration of events matching a specific sound category.
    public func duration(for category: SoundCategory) -> TimeInterval {
        events?.filter { $0.category == category }.reduce(0) { $0 + $1.snoreDuration } ?? 0
    }

    /// Duration during which the microphone was actually active and listening.
    public var monitoredDuration: TimeInterval {
        max(0, totalDuration - gapsDuration)
    }

    public var snoringPercentage: Double {
        totalDuration > 0 ? (snoringDuration / totalDuration) * 100 : 0
    }

    public var eventsCount: Int {
        events?.count ?? 0
    }

    public var eventsPerHour: Double {
        totalDuration > 0 ? Double(eventsCount) / (totalDuration / 3600) : 0
    }

    /// Percentage breakdown of sleep stages when Watch data is available.
    public var stageStats: StageStats? {
        guard let segments = sleepStageSegments, !segments.isEmpty else { return nil }
        let total = segments.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return nil }

        let awake = segments.filter { $0.stage == .awake }.reduce(0) { $0 + $1.duration }
        let rem = segments.filter { $0.stage == .rem }.reduce(0) { $0 + $1.duration }
        let light = segments.filter { $0.stage == .light }.reduce(0) { $0 + $1.duration }
        let deep = segments.filter { $0.stage == .deep }.reduce(0) { $0 + $1.duration }

        return StageStats(
            awakePct: (awake / total) * 100,
            remPct: (rem / total) * 100,
            lightPct: (light / total) * 100,
            deepPct: (deep / total) * 100
        )
    }

    public var sleepScore: Int {
        let events = self.events ?? []
        let snoringEvents = events.filter { $0.category == .snoring }
        let totalDuration = self.totalDuration
        let eventCount = snoringEvents.count

        guard totalDuration > 0 else {
            return 100
        }

        // If there are mic-paused gaps but no saved events, snoring was still
        // inferred (melody only plays after detection). Score based on gaps alone.
        if eventCount == 0 {
            if gapsDuration > 0 {
                let inferredSnoringPercentage = (gapsDuration / totalDuration) * 100
                let snoringPenalty = min(Int(inferredSnoringPercentage * 0.7), 70)
                return max(0, 100 - snoringPenalty)
            }
            return 100
        }

        var detectedSnoringDuration: TimeInterval = 0
        var lightDuration: TimeInterval = 0
        var loudDuration: TimeInterval = 0
        var epicDuration: TimeInterval = 0

        for event in snoringEvents {
            let duration = event.snoreDuration
            detectedSnoringDuration += duration
            switch event.intensity {
            case .light:
                lightDuration += duration
            case .loud:
                loudDuration += duration
            case .epic:
                epicDuration += duration
            case .quiet:
                break
            }
        }

        let sessionDuration = totalDuration
        guard sessionDuration > 0 else { return 100 }

        // Total snoring duration is the sum of detected snoring episode spans.
        // Recording gaps are excluded — the soothing melody may have stopped the snoring.
        let totalSnoringDuration = snoringDuration
        let snoringPercentage = (totalSnoringDuration / sessionDuration) * 100
        let snoringPenalty = min(Int(snoringPercentage * 0.7), 70)
        let eventsPenalty = min(Int(Double(eventCount) / (sessionDuration / 3600) * 2), 20)

        // Intensity ratios use only detected snoring as the denominator because we have no
        // spectral data during gaps. This conservatively reduces the intensity penalty.
        let lightRatio = detectedSnoringDuration > 0 ? lightDuration / detectedSnoringDuration : 0
        let loudRatio = detectedSnoringDuration > 0 ? loudDuration / detectedSnoringDuration : 0
        let epicRatio = detectedSnoringDuration > 0 ? epicDuration / detectedSnoringDuration : 0
        let intensityPenalty = min(Int(lightRatio * 10 + loudRatio * 20 + epicRatio * 30), 30)

        // Sleep talking penalty — only applies when sleep talking events exist.
        // Weighted ~half of snoring: less severe but still a genuine fragmentation event.
        let sleepTalkingPenalty: Int
        if sleepTalkingEvents > 0 {
            let talkingPctPenalty = sleepTalkingPercentage * 0.35
            let talkingFreqPenalty = sleepTalkingEventsPerHour * 0.8
            sleepTalkingPenalty = min(Int(talkingPctPenalty + talkingFreqPenalty), 15)
        } else {
            sleepTalkingPenalty = 0
        }

        // Sleep stage penalty — only applies when Watch/HealthKit data is available.
        // Evidence-based thresholds: deep ≥15%, REM ≥18%, awake ≤8%.
        let stagePenalty: Int
        if let stats = stageStats {
            let deepDeficit = max(0, (15 - stats.deepPct) * 0.6)
            let remDeficit = max(0, (18 - stats.remPct) * 0.4)
            let awakeExcess = max(0, (stats.awakePct - 8) * 1.0)
            stagePenalty = min(Int(deepDeficit + remDeficit + awakeExcess), 15)
        } else {
            stagePenalty = 0
        }

        return max(0, 100 - snoringPenalty - eventsPenalty - intensityPenalty
                   - sleepTalkingPenalty - stagePenalty)
    }
}
