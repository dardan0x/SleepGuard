import AudioEngine
import Env
import Foundation
import Models
import Observation

@MainActor
@Observable
public final class SessionManager {
    public static let shared = SessionManager()

    public var currentSession: SleepSession?
    public var isRecording = false
    public var completedSession: SleepSession?
    public var isProcessingSession = false

    /// Real-time audio level for UI observation
    public var currentDB: Float = -160.0
    public var currentSnoringState: SnoringState = .none
    public var eventsCount: Int = 0

    private let audioRecorder = AudioRecorder.shared
    private let snoreDetector = SnoreDetector.shared
    private let soothingMelodyPlayer = SoothingMelodyPlayer.shared

    // MARK: - Event tracking state

    private var activeEventStart: Date?
    private var activeEventIntensity: SnoreIntensity?
    private var activeEventDBSum: Double = 0
    private var activeEventDBCount: Int = 0
    private var activeEventPeakDB: Double = 0
    private var lastSnoringSampleTime: Date?
    private let eventGapThreshold: TimeInterval = 3.0
    private let melodyAutoStopThreshold: TimeInterval = 4.0

    /// Require 3 consecutive snoring samples (≈150 ms at 20 Hz) before starting an event.
    /// Filters out brief transient sounds (bed creaks, taps, notifications).
    private var consecutiveSnoreSamples: Int = 0
    private let requiredConsecutiveSamples: Int = 3

    // Burst tracking: continuous snoring segments within the active event
    private var activeBurstStart: Date?
    private var completedBursts: [(start: Date, end: Date)] = []

    // MARK: - Session aggregate state

    private var totalDBSum: Double = 0
    private var totalDBCount: Int = 0
    private var sessionSnoringDuration: TimeInterval = 0
    private var lastUpdateTime: Date?
    private var processingTask: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle

    public func startSession() throws {
        resetTrackingState()
        processingTask?.cancel()
        soothingMelodyPlayer.resetSessionMute()

        let session = SleepSession(startDate: Date())
        let audioURL = audioFileURL(for: session.id)
        session.audioFileURL = AudioFileURLResolver.filename(from: audioURL)
        currentSession = session

        try audioRecorder.startRecording(audioFileURL: audioURL)
        isRecording = true
        currentDB = -160.0
        currentSnoringState = .none
        eventsCount = 0

        Task {
            await SessionRawLogWriter.shared.start(sessionID: session.id)
        }

        // Drive processAudioLevel from SessionManager so it survives background.
        processingTask = Task { @MainActor in
            while !Task.isCancelled {
                let saConf = SoundAnalysisDetector.shared.snoreConfidence
                processAudioLevel(
                    db: audioRecorder.currentDB,
                    spectralScore: audioRecorder.spectralScore,
                    snoreConfidence: saConf
                )
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    public func stopSession() async -> SleepSession? {
        isProcessingSession = true
        defer { isProcessingSession = false }

        processingTask?.cancel()
        processingTask = nil
        audioRecorder.stopRecording()
        soothingMelodyPlayer.stop()
        isRecording = false

        // Finalize any in-progress snore event (include trailing gap since user stopped mid-session)
        if activeEventStart != nil {
            finalizeActiveEvent()
        }

        guard let session = currentSession else { return nil }

        let now = Date()

        session.endDate = now
        session.averageDB = totalDBCount > 0 ? totalDBSum / Double(totalDBCount) : 0
        eventsCount = session.eventsCount

        // Extract per-event clips and spectral features; preserve full session as raw data
        if let events = session.events, !events.isEmpty,
           let sessionURL = AudioFileURLResolver.resolve(session.audioFileURL)
        {
            let docs = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
            let results = await AudioClipExtractor.extractClips(
                from: sessionURL,
                events: events,
                sessionStart: session.startDate,
                padding: 0.0,
                outputDirectory: docs
            )
            for result in results {
                if let event = events.first(where: { $0.id == result.eventID }) {
                    event.audioFileURL = AudioFileURLResolver.filename(from: result.clipURL)
                    event.dominantFrequency = result.dominantFrequency
                    event.spectralCentroid = result.spectralCentroid
                    event.lowFreqRatio = result.lowFreqRatio
                }
            }
            // Preserve full session audio for future re-processing (threshold changes, migrations).
            // Clips become the primary playback source; raw file is the ground-truth archive.
            if !results.isEmpty {
                session.rawAudioFileURL = session.audioFileURL
                session.audioFileURL = nil
            }
            // If clips failed to extract, leave audioFileURL pointing to the full session
            // so playback and raw data both remain available.
        }

        // Save raw classification log
        let logFilename = await SessionRawLogWriter.shared.stop()
        session.rawLogFileURL = logFilename

        let result = session
        completedSession = result
        currentSession = nil
        resetTrackingState()
        return result
    }

    public func discardCompletedSession() {
        // Delete event clips
        if let events = completedSession?.events {
            for event in events {
                if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        // Delete legacy full session file if present (pre-raw-audio sessions)
        if let url = AudioFileURLResolver.resolve(completedSession?.audioFileURL) {
            try? FileManager.default.removeItem(at: url)
        }
        // Delete raw full session archive
        if let url = AudioFileURLResolver.resolve(completedSession?.rawAudioFileURL) {
            try? FileManager.default.removeItem(at: url)
        }
        // Delete raw classification log
        if let url = AudioFileURLResolver.resolve(completedSession?.rawLogFileURL) {
            try? FileManager.default.removeItem(at: url)
        }
        completedSession = nil
    }

    /// Stops the current recording and discards the session without presenting the summary.
    /// Used when the user explicitly chooses to stop a session that is below the minimum duration.
    public func stopAndDiscardSession() {
        processingTask?.cancel()
        processingTask = nil
        audioRecorder.stopRecording()
        soothingMelodyPlayer.stop()
        isRecording = false

        if activeEventStart != nil {
            finalizeActiveEvent()
        }

        // Delete the session's audio file and clean up
        if let session = currentSession {
            if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
                try? FileManager.default.removeItem(at: url)
            }
            if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
                try? FileManager.default.removeItem(at: url)
            }
        }

        currentSession = nil
        resetTrackingState()
    }

    // MARK: - Real-time audio processing

    /// Call this from the view when `audioRecorder.currentDB` changes.
    public func processAudioLevel(db: Float) {
        processAudioLevel(db: db, spectralScore: 0, snoreConfidence: 0)
    }

    /// Call this from the view when audio features are available.
    public func processAudioLevel(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) {
        guard isRecording, let session = currentSession else { return }

        let now = Date()
        let rawDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        let timeDelta = min(rawDelta, 0.5) // Cap to avoid spikes after background/resume
        lastUpdateTime = now

        currentDB = db

        // Update running aggregates
        totalDBSum += Double(db)
        totalDBCount += 1
        if Double(db) > session.peakDB {
            session.peakDB = Double(db)
        }

        // Classify snoring state (SoundAnalysis → FFT → thresholds)
        let state = snoreDetector.classify(db: db, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
        #if DEBUG
        if snoreConfidence > 0.1 || spectralScore > 0.1 {
            print("[SessionManager] classify db=\(String(format: "%.1f", db)) spectral=\(String(format: "%.2f", spectralScore)) snoreConf=\(String(format: "%.2f", snoreConfidence)) → \(state)")
        }
        #endif

        // Update display state immediately for UI responsiveness
        currentSnoringState = state

        // Append to raw classification log for future re-processing
        Task {
            await SessionRawLogWriter.shared.append(
                db: db,
                spectralScore: spectralScore,
                snoreConfidence: snoreConfidence,
                state: state
            )
        }

        // Accumulate snoring duration
        if state != .none {
            sessionSnoringDuration += timeDelta
        }

        // Handle event tracking with debounce gap + per-burst tracking
        if state != .none {
            consecutiveSnoreSamples += 1
            lastSnoringSampleTime = now
            guard consecutiveSnoreSamples >= requiredConsecutiveSamples else {
                // Not yet sustained enough to start/extend an event
                return
            }
            if activeEventStart == nil {
                // New event starts — backdate to when sustained detection began
                let backdate = TimeInterval(requiredConsecutiveSamples - 1) * 0.05
                activeEventStart = now.addingTimeInterval(-backdate)
                activeEventDBSum = Double(db)
                activeEventDBCount = 1
                activeEventPeakDB = Double(db)
                activeEventIntensity = intensity(from: state)
                activeBurstStart = activeEventStart
                print("[SessionManager] 🔔 New snore event started, calling playIfNeeded()")
                soothingMelodyPlayer.playIfNeeded()
            } else {
                // Event already active
                activeEventDBSum += Double(db)
                activeEventDBCount += 1
                if Double(db) > activeEventPeakDB {
                    activeEventPeakDB = Double(db)
                }
                let currentIntensity = intensity(from: state)
                if intensityRank(currentIntensity) > intensityRank(activeEventIntensity ?? .quiet) {
                    activeEventIntensity = currentIntensity
                }
                // Start a new burst if we resumed after a brief gap
                if activeBurstStart == nil {
                    activeBurstStart = now
                }
            }
        } else {
            consecutiveSnoreSamples = 0
            // Silence — close current burst if open
            if let burstStart = activeBurstStart {
                completedBursts.append((start: burstStart, end: now))
                activeBurstStart = nil
            }
            // Finalize event if silence exceeded debounce threshold
            if let lastSnore = lastSnoringSampleTime,
               activeEventStart != nil,
               now.timeIntervalSince(lastSnore) >= eventGapThreshold
            {
                print("[SessionManager] Silence for \(eventGapThreshold)s — finalizing snore event")
                finalizeActiveEvent()
            }

            // Auto-stop soothing melody if no snore detected for the threshold duration
            if let lastSnore = lastSnoringSampleTime,
               now.timeIntervalSince(lastSnore) >= melodyAutoStopThreshold,
               soothingMelodyPlayer.isPlaying
            {
                print("[SessionManager] No snore for \(melodyAutoStopThreshold)s — auto-stopping melody")
                soothingMelodyPlayer.stop()
            }
        }

        // Update stored aggregate (averageDB only; others are computed on demand)
        if totalDBCount > 0 {
            session.averageDB = totalDBSum / Double(totalDBCount)
        }
    }

    // MARK: - Private helpers

    private func resetTrackingState() {
        activeEventStart = nil
        activeEventIntensity = nil
        activeEventDBSum = 0
        activeEventDBCount = 0
        activeEventPeakDB = 0
        totalDBSum = 0
        totalDBCount = 0
        sessionSnoringDuration = 0
        lastUpdateTime = nil
        lastSnoringSampleTime = nil
        activeBurstStart = nil
        consecutiveSnoreSamples = 0
        completedBursts.removeAll(keepingCapacity: false)
    }

    private func finalizeActiveEvent() {
        guard let startTime = activeEventStart, let session = currentSession else {
            print("[SessionManager] finalizeActiveEvent() — no active event or session")
            return
        }
        print("[SessionManager] Finalizing snore event at \(startTime)")

        // Close any open burst
        if let burstStart = activeBurstStart {
            completedBursts.append((start: burstStart, end: lastSnoringSampleTime ?? Date()))
            activeBurstStart = nil
        }

        // Build burst models with offsets relative to event start
        let bursts = completedBursts.map { SnoreBurst(
            startOffset: $0.start.timeIntervalSince(startTime),
            endOffset: $0.end.timeIntervalSince(startTime)
        ) }

        let eventSpan = (lastSnoringSampleTime ?? Date()).timeIntervalSince(startTime)

        // Respect user's minimum snore duration setting (default 2 s) instead of
        // hardcoding 0.5 s. This filters out brief breathing waves and transients.
        let minDuration = UserPreferences.shared.minSnoreDuration
        guard eventSpan >= minDuration else {
            activeEventStart = nil
            activeEventIntensity = nil
            activeEventDBSum = 0
            activeEventDBCount = 0
            activeEventPeakDB = 0
            completedBursts.removeAll()
            return
        }

        let event = SnoreEvent(
            timestamp: startTime,
            intensity: activeEventIntensity ?? .quiet,
            averageDB: activeEventDBCount > 0 ? activeEventDBSum / Double(activeEventDBCount) : 0,
            peakDB: activeEventPeakDB,
            bursts: bursts.isEmpty ? nil : bursts
        )
        event.session = session

        if session.events == nil {
            session.events = []
        }
        session.events?.append(event)
        eventsCount = session.events?.count ?? 0

        activeEventStart = nil
        activeEventIntensity = nil
        activeEventDBSum = 0
        activeEventDBCount = 0
        activeEventPeakDB = 0
        completedBursts.removeAll(keepingCapacity: false)
    }

    private func audioFileURL(for sessionID: UUID) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("session_\(sessionID.uuidString).caf")
    }

    private func intensity(from state: SnoringState) -> SnoreIntensity {
        switch state {
        case .quiet: return .quiet
        case .light: return .light
        case .loud: return .loud
        case .none: return .quiet
        }
    }

    private func intensityRank(_ intensity: SnoreIntensity) -> Int {
        switch intensity {
        case .quiet: return 0
        case .light: return 1
        case .loud: return 2
        }
    }
}
