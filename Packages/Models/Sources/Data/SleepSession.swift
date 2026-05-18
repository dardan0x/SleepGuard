import Foundation
import SwiftData

@Model
public final class SleepSession {
    @Attribute(.unique) public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var averageDB: Double
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

    public static let minimumSaveDuration: TimeInterval = 600

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
        let detected = events?.reduce(0) { $0 + $1.snoreDuration } ?? 0
        return detected + gapsDuration
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

    public var sleepScore: Int {
        let events = self.events ?? []
        let totalDuration = self.totalDuration
        let eventCount = events.count

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

        for event in events {
            let duration = event.snoreDuration
            detectedSnoringDuration += duration
            switch event.intensity {
            case .light:
                lightDuration += duration
            case .loud:
                loudDuration += duration
            case .quiet:
                break
            }
        }

        let sessionDuration = totalDuration
        guard sessionDuration > 0 else { return 100 }

        // Total snoring duration includes detected bursts + inferred snoring during mic-paused gaps.
        let totalSnoringDuration = snoringDuration
        let snoringPercentage = (totalSnoringDuration / sessionDuration) * 100
        let snoringPenalty = min(Int(snoringPercentage * 0.7), 70)
        let eventsPenalty = min(Int(Double(eventCount) / (sessionDuration / 3600) * 2), 20)

        // Intensity ratios use only detected snoring as the denominator because we have no
        // spectral data during gaps. This conservatively reduces the intensity penalty.
        let lightRatio = detectedSnoringDuration > 0 ? lightDuration / detectedSnoringDuration : 0
        let loudRatio = detectedSnoringDuration > 0 ? loudDuration / detectedSnoringDuration : 0
        let intensityPenalty = min(Int(lightRatio * 10 + loudRatio * 20), 20)

        return max(0, 100 - snoringPenalty - eventsPenalty - intensityPenalty)
    }
}
