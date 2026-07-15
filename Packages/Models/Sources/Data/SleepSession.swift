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

    /// Intervals when the microphone was paused (e.g. during Snore Interrupter playback).
    /// Used to compute monitoredDuration and surface detection blind spots in the UI.
    public var recordingGaps: [RecordingGap]?

    /// Why the session ended early (e.g. "low_battery"). Set when the app force-saves
    /// to preserve data before the phone shuts down. nil for normal user-stopped sessions.
    public var terminationReason: String?

    /// Optional sleep stage segments sourced from Apple Health (Apple Watch).
    /// nil when no Watch data is available for this session.
    public var sleepStageSegments: [SleepStageSegment]?

    /// Cached values to avoid faulting the `events` relationship on app reopen.
    /// Set when the session is saved; used by `sleepScore` and `snoringDuration`.
    public var hasCachedScore: Bool = false
    public var cachedSleepScore: Int = 0
    public var cachedSnoringDuration: TimeInterval = 0

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
        if hasCachedScore {
            return cachedSnoringDuration
        }
        let snoringEvents = events?.filter { $0.category == .snoring } ?? []
        let eventDuration = snoringEvents.reduce(0) { $0 + $1.snoreDuration }

        // Only count gaps where snoring actually resumed. A paused microphone
        // doesn't prove snoring continued — we verify it with a short breathing
        // delay after the melody stops. Legacy gaps default to `snoringResumed`
        // so existing sessions keep their previous behavior.
        let countableGaps = (recordingGaps ?? []).filter(\.snoringResumed)
        let countableGapDuration = countableGaps.reduce(0) { $0 + $1.duration }
        guard countableGapDuration > 0 else { return eventDuration }

        // New sessions: events span gaps (event duration includes melody time).
        // Old sessions: events don't span gaps — add countable gap duration manually.
        // Detect old sessions by checking if any countable gap is NOT fully covered.
        let sessionStart = startDate.timeIntervalSinceReferenceDate
        let hasUncoveredGap = countableGaps.contains { gap in
            let gapStart = sessionStart + gap.startOffset
            let gapEnd = gapStart + gap.duration
            let covered = snoringEvents.contains { event in
                let eventStart = event.timestamp.timeIntervalSinceReferenceDate
                let eventEnd = eventStart + event.snoreDuration
                return eventStart <= gapStart && eventEnd >= gapEnd
            }
            return !covered
        }
        return eventDuration + (hasUncoveredGap ? countableGapDuration : 0)
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

    /// Groups adjacent snoring events within a 5-minute gap into episodes.
    /// This reduces visual clutter and false-positive event counts while
    /// preserving total snoring duration.
    public var snoringEpisodes: [SnoringEpisode] {
        let snoringEvents = (events ?? [])
            .filter { $0.category == .snoring }
            .sorted(by: { $0.timestamp < $1.timestamp })

        guard !snoringEvents.isEmpty else { return [] }

        let mergeGap: TimeInterval = 300

        var episodes: [SnoringEpisode] = []
        var currentEvents: [SnoreEvent] = [snoringEvents[0]]
        var currentEnd = snoringEvents[0].timestamp.addingTimeInterval(snoringEvents[0].snoreDuration)

        for event in snoringEvents.dropFirst() {
            let eventStart = event.timestamp
            if eventStart.timeIntervalSince(currentEnd) <= mergeGap {
                currentEvents.append(event)
                currentEnd = max(currentEnd, eventStart.addingTimeInterval(event.snoreDuration))
            } else {
                let maxIntensity = currentEvents.map(\.intensity).max(by: { $0.rank < $1.rank }) ?? .quiet
                episodes.append(SnoringEpisode(
                    id: currentEvents[0].id,
                    startTime: currentEvents[0].timestamp,
                    duration: currentEnd.timeIntervalSince(currentEvents[0].timestamp),
                    intensity: maxIntensity,
                    events: currentEvents
                ))
                currentEvents = [event]
                currentEnd = eventStart.addingTimeInterval(event.snoreDuration)
            }
        }

        let maxIntensity = currentEvents.map(\.intensity).max(by: { $0.rank < $1.rank }) ?? .quiet
        episodes.append(SnoringEpisode(
            id: currentEvents[0].id,
            startTime: currentEvents[0].timestamp,
            duration: currentEnd.timeIntervalSince(currentEvents[0].timestamp),
            intensity: maxIntensity,
            events: currentEvents
        ))

        return episodes
    }

    /// Episodes with enough total snoring duration to be worth displaying.
    /// Hides micro-episodes that are likely false positives while still
    /// counting them in `snoringDuration`. Episodes finalized after the
    /// post-melody breathing delay use pre-melody duration, so gap-only
    /// episodes naturally fall below the threshold and stay hidden.
    public var displayableSnoringEpisodes: [SnoringEpisode] {
        snoringEpisodes.filter { $0.snoreDuration >= 3 }
    }

    /// The events to play when a list row for `event` is tapped.
    ///
    /// Snoring rows represent a whole episode but are keyed by the episode's
    /// single representative event, so loading only `[event]` plays just that
    /// clip — making the player's total far shorter than the duration shown on
    /// the row (which sums every clip in the episode). This returns the full
    /// episode's events, time-ordered, so the player total matches the row.
    /// Non-snoring events (sleep talking, noise) are standalone and return `[event]`.
    public func episodePlaybackEvents(for event: SnoreEvent) -> [SnoreEvent] {
        if let episode = displayableSnoringEpisodes.first(where: {
            $0.representativeEvent?.id == event.id
        }) {
            return episode.events.sorted(by: { $0.timestamp < $1.timestamp })
        }
        return [event]
    }

    /// Event count using displayable snoring episodes.
    /// Non-snoring events are still counted individually.
    public var eventsCount: Int {
        let otherEvents = (events ?? []).filter { $0.category != .snoring }.count
        return displayableSnoringEpisodes.count + otherEvents
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
        if hasCachedScore {
            return cachedSleepScore
        }
        return sleepScore(using: .default)
    }

    /// Computes the sleep score using the supplied configuration.
    ///
    /// This method always reads events and recomputes; it does not use the
    /// cached score. Callers that iterate many sessions should use the
    /// `sleepScore` property instead to avoid SwiftData relationship faulting.
    public func sleepScore(using config: SleepScoreConfig) -> Int {
        let events = self.events ?? []
        let snoringEvents = events.filter { $0.category == .snoring }
        let totalDuration = self.totalDuration
        let eventCount = displayableSnoringEpisodes.count

        guard totalDuration > 0 else {
            return config.maxScore
        }

        var detectedSnoringDuration: TimeInterval = 0
        var lightDuration: TimeInterval = 0
        var loudDuration: TimeInterval = 0
        var epicDuration: TimeInterval = 0

        for event in snoringEvents {
            // Use burst sum for intensity ratios, not the full event span.
            // Event span includes melody gaps where no spectral data exists;
            // we should not penalize intensity for time we couldn't measure.
            let detectedDuration = event.bursts?.reduce(0) { $0 + $1.duration } ?? event.snoreDuration
            detectedSnoringDuration += detectedDuration
            switch event.intensity {
            case .light:
                lightDuration += detectedDuration
            case .loud:
                loudDuration += detectedDuration
            case .epic:
                epicDuration += detectedDuration
            case .quiet:
                break
            }
        }

        let sessionDuration = totalDuration

        // Total snoring duration includes both detected events and recording gaps.
        // Gaps occur when the Snore Interrupter plays after snoring detection;
        // that time counts as snoring since the melody only triggers on confirmed samples.
        let totalSnoringDuration = snoringDuration
        let snoringPercentage = (totalSnoringDuration / sessionDuration) * 100
        let snoringPenalty = min(Int(snoringPercentage * config.snoringMultiplier), config.snoringPenaltyCap)
        let eventsPenalty = min(Int(Double(eventCount) / (sessionDuration / 3600) * config.eventsPerHourMultiplier), config.eventsPenaltyCap)

        // Intensity ratios use only detected snoring as the denominator because we have no
        // spectral data during gaps. This conservatively reduces the intensity penalty.
        let lightRatio = detectedSnoringDuration > 0 ? lightDuration / detectedSnoringDuration : 0
        let loudRatio = detectedSnoringDuration > 0 ? loudDuration / detectedSnoringDuration : 0
        let epicRatio = detectedSnoringDuration > 0 ? epicDuration / detectedSnoringDuration : 0
        let intensityPenalty = min(Int(
            lightRatio * config.lightIntensityMultiplier
                + loudRatio * config.loudIntensityMultiplier
                + epicRatio * config.epicIntensityMultiplier
        ), config.intensityPenaltyCap)

        // Sleep talking penalty — only applies when sleep talking events exist.
        // Weighted ~half of snoring: less severe but still a genuine fragmentation event.
        let sleepTalkingPenalty: Int
        if sleepTalkingEvents > 0 {
            let talkingPctPenalty = sleepTalkingPercentage * config.sleepTalkingPercentageMultiplier
            let talkingFreqPenalty = sleepTalkingEventsPerHour * config.sleepTalkingFrequencyMultiplier
            sleepTalkingPenalty = min(Int(talkingPctPenalty + talkingFreqPenalty), config.sleepTalkingPenaltyCap)
        } else {
            sleepTalkingPenalty = 0
        }

        // Sleep stage penalty — only applies when Watch/HealthKit data is available.
        // Evidence-based thresholds: deep ≥15%, REM ≥18%, awake ≤8%.
        let stagePenalty: Int
        if let stats = stageStats {
            let deepDeficit = max(0, (config.deepPctTarget - stats.deepPct) * config.deepDeficitMultiplier)
            let remDeficit = max(0, (config.remPctTarget - stats.remPct) * config.remDeficitMultiplier)
            let awakeExcess = max(0, (stats.awakePct - config.awakePctTarget) * config.awakeExcessMultiplier)
            stagePenalty = min(Int(deepDeficit + remDeficit + awakeExcess), config.stagePenaltyCap)
        } else {
            stagePenalty = 0
        }

        // Sleep duration penalty — very short or very long nights both reduce quality.
        let sleepHours = totalDuration / 3600
        let shortSleepPenalty: Int
        if sleepHours >= config.shortSleepMinimumSessionHours {
            let shortSleepDeficit = max(0, config.shortSleepThresholdHours - sleepHours)
            shortSleepPenalty = min(Int(shortSleepDeficit * config.shortSleepMultiplier), config.shortSleepPenaltyCap)
        } else {
            shortSleepPenalty = 0
        }

        let longSleepExcess = max(0, sleepHours - config.longSleepThresholdHours)
        let longSleepPenalty = min(Int(longSleepExcess * config.longSleepMultiplier), config.longSleepPenaltyCap)

        return max(config.minScore, config.maxScore - snoringPenalty - eventsPenalty - intensityPenalty
                   - sleepTalkingPenalty - stagePenalty - shortSleepPenalty - longSleepPenalty)
    }
}
