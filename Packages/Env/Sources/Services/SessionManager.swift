import AudioEngine
import AVFoundation
import Env
import Foundation
import Models
import Observation
import UIKit

@MainActor
@Observable
public final class SessionManager {
    public static let shared = SessionManager()

    public var currentSession: SleepSession?
    public var isRecording = false
    public var completedSession: SleepSession?
    public var isProcessingSession = false
    public var isLiveSessionVisible = false

    /// Real-time audio level for UI observation
    public var currentDB: Float = -160.0
    public var currentDetectionState: DetectionState = .none
    public var currentSpeechDetected = false
    public var eventsCount: Int = 0

    private let audioRecorder = AudioRecorder.shared
    private let snoreDetector = SnoreDetector.shared
    private let speechDetector = SpeechDetector.shared
    private let soothingMelodyPlayer = SoothingMelodyPlayer.shared

    // MARK: - Event tracking state

    private var activeEventStart: Date?
    private var activeEventID: UUID?
    private var activeEventIntensity: SnoreIntensity?
    private var activeEventDBSum: Double = 0
    private var activeEventDBCount: Int = 0
    private var activeEventPeakDB: Double = 0
    private var activeEventConfidenceSum: Double = 0
    private var activeEventConfidenceCount: Int = 0
    private var activeEventSpectralSum: Double = 0
    private var activeEventSpectralCount: Int = 0
    private var lastSnoringSampleTime: Date?
    private let eventGapThreshold: TimeInterval = 10.0
    /// Require 3 consecutive snoring samples (≈150 ms at 20 Hz) before starting an event.
    /// Filters out brief transient sounds (bed creaks, taps, notifications).
    private var consecutiveSnoreSamples: Int = 0
    private let requiredConsecutiveSamples: Int = 3

    /// Require 3 consecutive non-snoring samples before stopping the melody.
    /// Keeps melody playing through brief breathing gaps.
    private var consecutiveNonSnoreSamples: Int = 0
    private let requiredNonSnoreSamplesToStop: Int = 3

    /// Minimum time the soothing melody must play before it can be stopped by non-snore detection.
    private let melodyMinPlayDuration: TimeInterval = 4.0
    /// After the melody stops, wait this long for snoring to resume before
    /// deciding the gap should not count as snoring time.
    private let postMelodyBreathingDelay: TimeInterval = 3.0
    private var melodyStartTime: Date?
    private var melodyResumeTime: Date?
    private var postMelodySnoringDetected: Bool = false

    // Burst tracking: continuous snoring segments within the active event
    private var activeBurstStart: Date?
    private var completedBursts: [(start: Date, end: Date)] = []

    // MARK: - Speech event tracking state

    private var activeSpeechEventStart: Date?
    private var activeSpeechEventDBSum: Double = 0
    private var activeSpeechEventDBCount: Int = 0
    private var activeSpeechEventPeakDB: Double = 0
    private var lastSpeechSampleTime: Date?
    private var consecutiveSpeechSamples: Int = 0
    private let requiredConsecutiveSpeechSamples: Int = 3

    // MARK: - Session aggregate state

    private var totalDBSum: Double = 0
    private var totalDBCount: Int = 0
    private var sessionSnoringDuration: TimeInterval = 0
    private var lastUpdateTime: Date?
    private var processingTask: Task<Void, Never>?
    private var batteryCheckCounter = 0

    // MARK: - Per-event compression tasks

    private var pendingEventTasks: [Task<Void, Never>] = []

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMelodyDidStop),
            name: .soothingMelodyDidStop,
            object: nil
        )
        #if !targetEnvironment(simulator)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    @objc private func handleMelodyDidStop() {
        guard let start = melodyStartTime else { return }
        let duration = Date().timeIntervalSince(start)
        logRecordingGap(start: start, duration: duration, snoringResumed: false)
        melodyStartTime = nil
        // Don't extend lastSnoringSampleTime yet. We wait for a short breathing
        // delay after mic resume to verify snoring actually continued; only then
        // does the gap count as snoring time.
        if activeEventStart != nil {
            melodyResumeTime = Date()
            postMelodySnoringDetected = false
        }
        // Reset non-snore counter so stale data from the pause doesn't
        // immediately trigger a melody stop when audio resumes.
        consecutiveNonSnoreSamples = 0
    }

    /// Logs a recording gap directly on the session. Called whenever the soothing melody
    /// stops (mic resumes), ensuring gaps are counted even if notification delivery fails.
    private func logRecordingGap(start: Date, duration: TimeInterval, snoringResumed: Bool = true) {
        guard let session = currentSession, duration > 0 else { return }
        let startOffset = start.timeIntervalSince(session.startDate)
        guard startOffset >= 0 else { return }
        var gaps = session.recordingGaps ?? []
        gaps.append(RecordingGap(startOffset: startOffset, duration: duration, snoringResumed: snoringResumed))
        session.recordingGaps = gaps
        print("[SessionManager] Logged gap: startOffset=\(String(format: "%.1f", startOffset))s duration=\(String(format: "%.1f", duration))s snoringResumed=\(snoringResumed)")
    }

    /// Marks the most recent recording gap as having confirmed snoring resumption.
    /// Called when sustained snoring is detected within the post-melody breathing delay.
    private func markLastGapSnoringResumed() {
        guard let session = currentSession, var gaps = session.recordingGaps, !gaps.isEmpty else { return }
        gaps[gaps.count - 1].snoringResumed = true
        session.recordingGaps = gaps
    }

    // MARK: - Lifecycle

    public func startSession() throws {
        resetTrackingState()
        processingTask?.cancel()
        soothingMelodyPlayer.resetSessionMute()

        // Clean up any orphaned files from a previous force-closed session.
        PendingSessionStore.shared.cleanupIfNeeded()

        let session = SleepSession(startDate: Date())
        session.recordingGaps = []
        currentSession = session
        let sessionAudioFilename = UserPreferences.shared.preserveRawAudio ? "session_\(session.id.uuidString).caf" : nil
        PendingSessionStore.shared.setPending(sessionID: session.id, sessionAudioFilename: sessionAudioFilename)

        // Apply detection sensitivity thresholds before starting
        applyDetectionSensitivity()

        // Full-session raw audio is only recorded in debug mode for algorithm testing.
        let audioURL: URL?
        if UserPreferences.shared.preserveRawAudio {
            audioURL = audioFileURL(for: session.id)
            session.audioFileURL = AudioFileURLResolver.filename(from: audioURL!)
        } else {
            audioURL = nil
        }

        try audioRecorder.startRecording(audioFileURL: audioURL)
        isRecording = true
        currentDB = -160.0
        currentDetectionState = .none
        currentSpeechDetected = false
        eventsCount = 0

        Task {
            await SessionRawLogWriter.shared.start(sessionID: session.id)
        }

        // Drive processAudioLevel from SessionManager so it survives background.
        processingTask = Task { @MainActor in
            while !Task.isCancelled {
                let saConf = SoundAnalysisDetector.shared.snoreConfidence
                let saSpeechConf = SoundAnalysisDetector.shared.speechConfidence
                processAudioLevel(
                    db: audioRecorder.currentDB,
                    peakDB: audioRecorder.currentPeakDB,
                    spectralScore: audioRecorder.spectralScore,
                    snoreConfidence: saConf,
                    speechConfidence: saSpeechConf
                )
                batteryCheckCounter += 1
                if batteryCheckCounter >= 600 {
                    batteryCheckCounter = 0
                    checkBatteryLevel()
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func checkBatteryLevel() {
        #if targetEnvironment(simulator)
        return
        #else
        let level = UIDevice.current.batteryLevel
        guard level >= 0, level <= 0.02 else { return }
        print("[SessionManager] Battery level at \(Int(level * 100))% — force saving session")
        forceSaveDueToLowBattery()
        #endif
    }

    public func forceSaveDueToLowBattery() {
        Task { @MainActor in
            guard isRecording else { return }
            currentSession?.terminationReason = "low_battery"
            _ = await stopSession()
        }
    }

    public func stopSession() async -> SleepSession? {
        isProcessingSession = true
        defer { isProcessingSession = false }

        processingTask?.cancel()
        processingTask = nil

        soothingMelodyPlayer.stop()
        isRecording = false

        // Finalize any in-progress events BEFORE stopping the audio engine.
        // finalizeActiveEvent() calls finalizeEventFile() to capture the raw
        // .caf URL; if stopRecording() runs first, currentEventFile is nilled
        // and the event's audio is lost forever.
        if activeEventStart != nil {
            finalizeActiveEvent()
        }
        if activeSpeechEventStart != nil {
            finalizeActiveSpeechEvent()
        }

        audioRecorder.stopRecording()

        // Wait for any in-flight per-event compression tasks to finish.
        for task in pendingEventTasks {
            await task.value
        }
        pendingEventTasks.removeAll()

        guard let session = currentSession else { return nil }

        let now = Date()

        session.endDate = now
        session.averageDB = totalDBCount > 0 ? totalDBSum / Double(totalDBCount) : 0
        eventsCount = session.eventsCount

        // In debug mode with raw audio preserved, move the full session file to rawAudioFileURL
        // so event clips remain the primary playback source.
        if UserPreferences.shared.preserveRawAudio,
           let events = session.events, !events.isEmpty,
           session.rawAudioFileURL == nil,
           session.audioFileURL != nil
        {
            let hasClips = events.contains { $0.audioFileURL != nil }
            if hasClips {
                session.rawAudioFileURL = session.audioFileURL
                session.audioFileURL = nil
            }
        }

        // Save raw classification log
        let logFilename = await SessionRawLogWriter.shared.stop()
        session.rawLogFileURL = logFilename
        if let logFilename {
            PendingSessionStore.shared.addFile(logFilename)
        }

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
        PendingSessionStore.shared.cleanupIfNeeded()
        completedSession = nil
    }

    /// Stops the current recording and discards the session without presenting the summary.
    /// Used when the user explicitly chooses to stop a session that is below the minimum duration.
    public func stopAndDiscardSession() {
        Task { @MainActor in
            processingTask?.cancel()
            processingTask = nil

            soothingMelodyPlayer.stop()
            isRecording = false

            // Finalize events BEFORE stopping audio engine so file URLs are
            // captured while currentEventFile still exists.
            if activeEventStart != nil {
                finalizeActiveEvent()
            }
            if activeSpeechEventStart != nil {
                finalizeActiveSpeechEvent()
            }

            audioRecorder.stopRecording()

            // Wait for any in-flight compression tasks before deleting files.
            for task in pendingEventTasks {
                await task.value
            }
            pendingEventTasks.removeAll()

            // Delete the session's audio files and clean up
            if let session = currentSession {
                if let url = AudioFileURLResolver.resolve(session.audioFileURL) {
                    try? FileManager.default.removeItem(at: url)
                }
                if let url = AudioFileURLResolver.resolve(session.rawAudioFileURL) {
                    try? FileManager.default.removeItem(at: url)
                }
                // Delete per-event files
                if let events = session.events {
                    for event in events {
                        if let url = AudioFileURLResolver.resolve(event.audioFileURL) {
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                }
            }

            PendingSessionStore.shared.cleanupIfNeeded()
            currentSession = nil
            resetTrackingState()
        }
    }

    // MARK: - Real-time audio processing

    /// Call this from the view when `audioRecorder.currentDB` changes.
    public func processAudioLevel(db: Float) {
        processAudioLevel(db: db, peakDB: nil, spectralScore: 0, snoreConfidence: 0, speechConfidence: 0)
    }

    /// Call this from the view when audio features are available.
    public func processAudioLevel(db: Float, peakDB: Float? = nil, spectralScore: Float = 0, snoreConfidence: Float = 0, speechConfidence: Float = 0) {
        guard isRecording, let session = currentSession else { return }

        let now = Date()
        let rawDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        let timeDelta = min(rawDelta, 0.5) // Cap to avoid spikes after background/resume
        lastUpdateTime = now

        // Don't process stale audio data while the mic is paused for melody playback.
        // The tap is removed during pause, so currentDB/spectralScore/snoreConfidence
        // are stale. Processing them creates false events and prematurely stops the melody.
        guard !audioRecorder.isPaused else { return }

        currentDB = db

        // Update running aggregates
        totalDBSum += Double(db)
        totalDBCount += 1
        if Double(db) > session.peakDB {
            session.peakDB = Double(db)
        }

        // Classify snoring state (SoundAnalysis → FFT → thresholds).
        // Use peakDB for intensity — snoring is impulsive and peak carries
        // more perceptual loudness than RMS over a 23 ms buffer.
        let classifyDB = peakDB ?? db
        let state = snoreDetector.classify(db: classifyDB, spectralScore: spectralScore, snoreConfidence: snoreConfidence)
        #if DEBUG
        if snoreConfidence > 0.1 || spectralScore > 0.1 || speechConfidence > 0.1 {
            print("[SessionManager] classify rms=\(String(format: "%.1f", db)) peak=\(String(format: "%.1f", classifyDB)) spectral=\(String(format: "%.2f", spectralScore)) snoreConf=\(String(format: "%.2f", snoreConfidence)) speechConf=\(String(format: "%.2f", speechConfidence)) → snore=\(state) speech=\(speechDetector.isSpeechDetected)")
        }
        #endif

        // Update display state immediately for UI responsiveness
        currentDetectionState = state

        // Update parallel speech detection
        speechDetector.update(db: db, speechConfidence: speechConfidence)
        currentSpeechDetected = speechDetector.isSpeechDetected

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
            // Snoring takes priority — finalize any active speech event immediately
            if activeSpeechEventStart != nil {
                finalizeActiveSpeechEvent(endTime: now)
            }

            consecutiveSnoreSamples += 1
            consecutiveNonSnoreSamples = 0
            // During post-melody breathing delay, don't extend the event span
            // until sustained snoring is confirmed. Transient sounds shouldn't
            // make the gap count as snoring time.
            if melodyResumeTime == nil || postMelodySnoringDetected {
                lastSnoringSampleTime = now
            }
            guard consecutiveSnoreSamples >= requiredConsecutiveSamples else {
                // Not yet sustained enough to start/extend an event
                return
            }
            if activeEventStart == nil {
                // New event starts — backdate to when sustained detection began
                let backdate = TimeInterval(requiredConsecutiveSamples - 1) * 0.05
                activeEventStart = now.addingTimeInterval(-backdate)
                activeEventID = UUID()
                activeEventDBSum = Double(db)
                activeEventDBCount = 1
                activeEventPeakDB = Double(db)
                activeEventConfidenceSum = snoreConfidence > 0 ? Double(snoreConfidence) : 0
                activeEventConfidenceCount = snoreConfidence > 0 ? 1 : 0
                activeEventSpectralSum = spectralScore > 0 ? Double(spectralScore) : 0
                activeEventSpectralCount = spectralScore > 0 ? 1 : 0
                activeEventIntensity = intensity(from: state)
                activeBurstStart = activeEventStart

                // Start per-event audio recording
                if let eventID = activeEventID {
                    let fileURL = eventFileURL(eventID: eventID, sessionID: session.id)
                    do {
                        try audioRecorder.startEventFile(eventID: eventID, url: fileURL)
                        PendingSessionStore.shared.addFile(fileURL.lastPathComponent)
                    } catch {
                        print("[SessionManager] Failed to start event file: \(error)")
                    }
                }

                print("[SessionManager] 🔔 New snore event started, calling playIfNeeded()")
                let wasPlaying = soothingMelodyPlayer.isPlaying
                soothingMelodyPlayer.playIfNeeded()
                // If the melody just started, the mic is about to pause. Close the
                // audio file and current burst so they don't span the dead-mic
                // interval, but keep the event alive — snoring continues during
                // melody playback and the event duration will span the gap.
                if soothingMelodyPlayer.isPlaying && !wasPlaying {
                    melodyStartTime = now
                    // Close the event audio file; a new one will be started if
                    // snoring resumes after the melody.
                    _ = audioRecorder.finalizeEventFile()
                    // Close the current burst; post-melody snoring starts a new burst.
                    if let burstStart = activeBurstStart {
                        completedBursts.append((start: burstStart, end: lastSnoringSampleTime ?? now))
                        activeBurstStart = nil
                    }
                    lastUpdateTime = nil
                    consecutiveSnoreSamples = 0
                    consecutiveNonSnoreSamples = 0
                    // Intentionally NOT resetting activeEventStart/lastSnoringSampleTime
                    // so the event span covers the melody gap.
                }
            } else {
                // Event already active
                activeEventDBSum += Double(db)
                activeEventDBCount += 1
                if Double(db) > activeEventPeakDB {
                    activeEventPeakDB = Double(db)
                }
                if snoreConfidence > 0 {
                    activeEventConfidenceSum += Double(snoreConfidence)
                    activeEventConfidenceCount += 1
                }
                if spectralScore > 0 {
                    activeEventSpectralSum += Double(spectralScore)
                    activeEventSpectralCount += 1
                }
                let currentIntensity = intensity(from: state)
                if intensityRank(currentIntensity) > intensityRank(activeEventIntensity ?? .quiet) {
                    activeEventIntensity = currentIntensity
                }
                // Start a new burst if we resumed after a brief gap
                if activeBurstStart == nil {
                    activeBurstStart = now
                }

                // If we just resumed from a melody gap, confirm that snoring actually
                // resumed within the breathing delay. Only then does the gap count
                // as snoring time.
                if let resumeTime = melodyResumeTime, !postMelodySnoringDetected {
                    postMelodySnoringDetected = true
                    lastSnoringSampleTime = now
                    markLastGapSnoringResumed()
                    print("[SessionManager] Snoring resumed within breathing delay (\(String(format: "%.2f", now.timeIntervalSince(resumeTime)))s) — gap counts as snoring")
                }

                // Re-trigger melody if snoring resumes after a previous melody stopped.
                // The event stays open across melody gaps, so this is not a "new" event —
                // but the melody should still play again on sustained post-melody snoring.
                let wasPlaying = soothingMelodyPlayer.isPlaying
                soothingMelodyPlayer.playIfNeeded()
                if soothingMelodyPlayer.isPlaying && !wasPlaying {
                    melodyStartTime = now
                    // Close the event audio file; a new one will be started if
                    // snoring resumes after this melody.
                    _ = audioRecorder.finalizeEventFile()
                    // Close the current burst; post-melody snoring starts a new burst.
                    if let burstStart = activeBurstStart {
                        completedBursts.append((start: burstStart, end: lastSnoringSampleTime ?? now))
                        activeBurstStart = nil
                    }
                    lastUpdateTime = nil
                    consecutiveSnoreSamples = 0
                    consecutiveNonSnoreSamples = 0
                }
            }
        } else {
            // If the post-melody breathing delay expires without sustained snoring,
            // finalize the event using the pre-melody lastSnoringSampleTime so the
            // gap is not counted as snoring time.
            if let resumeTime = melodyResumeTime,
               activeEventStart != nil,
               !postMelodySnoringDetected,
               now.timeIntervalSince(resumeTime) >= postMelodyBreathingDelay
            {
                print("[SessionManager] Breathing delay expired without snoring resumption — finalizing pre-melody event")
                melodyResumeTime = nil
                finalizeActiveEvent()
                return
            }

            consecutiveSnoreSamples = 0
            consecutiveNonSnoreSamples += 1
            // Silence — close current burst if open
            if let burstStart = activeBurstStart {
                completedBursts.append((start: burstStart, end: now))
                activeBurstStart = nil
            }
            // Finalize event if silence exceeded debounce threshold.
            // Don't finalize while melody is playing — the mic is paused and
            // currentDB is stale, so silence detection is not trustworthy.
            if let lastSnore = lastSnoringSampleTime,
               activeEventStart != nil,
               now.timeIntervalSince(lastSnore) >= eventGapThreshold,
               !soothingMelodyPlayer.isPlaying
            {
                print("[SessionManager] Silence for \(eventGapThreshold)s — finalizing snore event")
                finalizeActiveEvent()
            }

            // Stop melody when sustained non-snore is detected (but respect minimum play duration)
            if consecutiveNonSnoreSamples >= requiredNonSnoreSamplesToStop,
               soothingMelodyPlayer.isPlaying
            {
                let minDurationMet = melodyStartTime.map { now.timeIntervalSince($0) >= melodyMinPlayDuration } ?? true
                guard minDurationMet else {
                    print("[SessionManager] Sustained non-snore detected but melody still within minimum play duration — keeping playing")
                    return
                }
                print("[SessionManager] Sustained non-snore — stopping melody")
                soothingMelodyPlayer.stop()
                consecutiveNonSnoreSamples = 0
            }

            // Speech event tracking (sleep talking)
            if UserPreferences.shared.detectSleepTalking {
                if currentSpeechDetected {
                    consecutiveSpeechSamples += 1
                    lastSpeechSampleTime = now
                    guard consecutiveSpeechSamples >= requiredConsecutiveSpeechSamples else {
                        return
                    }
                    if activeSpeechEventStart == nil {
                        let backdate = TimeInterval(requiredConsecutiveSpeechSamples - 1) * 0.05
                        activeSpeechEventStart = now.addingTimeInterval(-backdate)
                        activeSpeechEventDBSum = Double(db)
                        activeSpeechEventDBCount = 1
                        activeSpeechEventPeakDB = Double(db)
                        print("[SessionManager] 🗣️ New speech event started")
                    } else {
                        activeSpeechEventDBSum += Double(db)
                        activeSpeechEventDBCount += 1
                        if Double(db) > activeSpeechEventPeakDB {
                            activeSpeechEventPeakDB = Double(db)
                        }
                    }
                } else {
                    consecutiveSpeechSamples = 0
                    if let lastSpeech = lastSpeechSampleTime,
                       activeSpeechEventStart != nil,
                       now.timeIntervalSince(lastSpeech) >= eventGapThreshold
                    {
                        print("[SessionManager] Silence for \(eventGapThreshold)s — finalizing speech event")
                        finalizeActiveSpeechEvent()
                    }
                }
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
        activeEventID = nil
        activeEventIntensity = nil
        activeEventDBSum = 0
        activeEventDBCount = 0
        activeEventPeakDB = 0
        activeEventConfidenceSum = 0
        activeEventConfidenceCount = 0
        activeEventSpectralSum = 0
        activeEventSpectralCount = 0
        totalDBSum = 0
        totalDBCount = 0
        sessionSnoringDuration = 0
        lastUpdateTime = nil
        lastSnoringSampleTime = nil
        activeBurstStart = nil
        consecutiveSnoreSamples = 0
        consecutiveNonSnoreSamples = 0
        melodyStartTime = nil
        melodyResumeTime = nil
        postMelodySnoringDetected = false
        currentSpeechDetected = false
        activeSpeechEventStart = nil
        activeSpeechEventDBSum = 0
        activeSpeechEventDBCount = 0
        activeSpeechEventPeakDB = 0
        lastSpeechSampleTime = nil
        consecutiveSpeechSamples = 0
        completedBursts.removeAll(keepingCapacity: false)
        pendingEventTasks.removeAll(keepingCapacity: false)
    }

    private func finalizeActiveEvent(skipMinDuration: Bool = false) {
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

        // Discard events shorter than `minEventDuration` (sensitivity-dependent —
        // 2 s on Low to filter out transients, 0.5 s on High to catch isolated
        // single snores). When the mic is paused by soothing melody we always
        // lower to 0.5 s so the truncated event still has meaningful duration.
        let minDuration: TimeInterval = skipMinDuration ? 0.0 : minEventDuration
        guard eventSpan >= minDuration else {
            // Clean up the event file if one was started
            if let eventID = activeEventID {
                let fileURL = eventFileURL(eventID: eventID, sessionID: session.id)
                try? FileManager.default.removeItem(at: fileURL)
            }
            audioRecorder.finalizeEventFile()
            activeEventStart = nil
            activeEventID = nil
            activeEventIntensity = nil
            activeEventDBSum = 0
            activeEventDBCount = 0
            activeEventPeakDB = 0
            activeEventConfidenceSum = 0
            activeEventConfidenceCount = 0
            activeEventSpectralSum = 0
            activeEventSpectralCount = 0
            completedBursts.removeAll()
            return
        }

        let averageConfidence = activeEventConfidenceCount > 0 ? activeEventConfidenceSum / Double(activeEventConfidenceCount) : 0
        let averageSpectralScore = activeEventSpectralCount > 0 ? activeEventSpectralSum / Double(activeEventSpectralCount) : 0

        // Short events (< 3 s) require high confidence to avoid false positives.
        // ML-classified events must clear the sensitivity-specific high-confidence gate.
        // Spectral-only events (no ML confidence) must have a stronger spectral score.
        let shortEventThreshold: TimeInterval = 3.0
        if eventSpan < shortEventThreshold {
            let hasMLConfidence = activeEventConfidenceCount > 0
            let passesConfidence = hasMLConfidence
                ? averageConfidence >= Double(snoreDetector.highConfidenceGate)
                : averageSpectralScore >= 0.65
            if !passesConfidence {
                print("[SessionManager] Short event discarded: span \(String(format: "%.2f", eventSpan))s < \(shortEventThreshold)s, avgConf=\(String(format: "%.2f", averageConfidence)), avgSpectral=\(String(format: "%.2f", averageSpectralScore))")
                if let eventID = activeEventID {
                    let fileURL = eventFileURL(eventID: eventID, sessionID: session.id)
                    try? FileManager.default.removeItem(at: fileURL)
                }
                audioRecorder.finalizeEventFile()
                activeEventStart = nil
                activeEventID = nil
                activeEventIntensity = nil
                activeEventDBSum = 0
                activeEventDBCount = 0
                activeEventPeakDB = 0
                activeEventConfidenceSum = 0
                activeEventConfidenceCount = 0
                activeEventSpectralSum = 0
                activeEventSpectralCount = 0
                completedBursts.removeAll()
                return
            }
        }

        let event = SnoreEvent(
            id: activeEventID ?? UUID(),
            timestamp: startTime,
            category: .snoring,
            intensity: activeEventIntensity ?? .quiet,
            averageDB: activeEventDBCount > 0 ? activeEventDBSum / Double(activeEventDBCount) : 0,
            peakDB: activeEventPeakDB,
            averageConfidence: averageConfidence,
            averageSpectralScore: averageSpectralScore,
            bursts: bursts.isEmpty ? nil : bursts,
            duration: eventSpan
        )
        event.session = session

        if session.events == nil {
            session.events = []
        }
        session.events?.append(event)
        eventsCount = session.events?.count ?? 0

        // Close the event audio file and compress to .m4a
        let rawFileURL = audioRecorder.finalizeEventFile()
        if let rawFileURL = rawFileURL {
            let task = Task { @MainActor in
                let m4aURL = rawFileURL.deletingPathExtension().appendingPathExtension("m4a")
                if await self.compressEventFile(from: rawFileURL, to: m4aURL) {
                    let spectral = await AudioClipExtractor.analyzeSpectralFeatures(of: m4aURL)
                    event.audioFileURL = AudioFileURLResolver.filename(from: m4aURL)
                    event.dominantFrequency = spectral.dominantFrequency
                    event.spectralCentroid = spectral.spectralCentroid
                    event.lowFreqRatio = spectral.lowFreqRatio
                    PendingSessionStore.shared.addFile(m4aURL.lastPathComponent)
                    // Delete raw .caf
                    try? FileManager.default.removeItem(at: rawFileURL)
                }
            }
            pendingEventTasks.append(task)
        }

        activeEventStart = nil
        activeEventID = nil
        activeEventIntensity = nil
        activeEventDBSum = 0
        activeEventDBCount = 0
        activeEventPeakDB = 0
        activeEventConfidenceSum = 0
        activeEventConfidenceCount = 0
        activeEventSpectralSum = 0
        activeEventSpectralCount = 0
        melodyResumeTime = nil
        postMelodySnoringDetected = false
        completedBursts.removeAll(keepingCapacity: false)
    }

    private func finalizeActiveSpeechEvent(endTime: Date? = nil) {
        guard let startTime = activeSpeechEventStart, let session = currentSession else {
            return
        }
        print("[SessionManager] Finalizing speech event at \(startTime)")

        let eventEnd = endTime ?? (lastSpeechSampleTime ?? Date())
        let eventSpan = eventEnd.timeIntervalSince(startTime)

        // Discard events shorter than 0.5 s. Sleep talking utterances (single words,
        // mumbles, groans) are typically 0.5–2 s, much shorter than snoring epochs.
        guard eventSpan >= 0.5 else {
            print("[SessionManager] Speech event discarded: span \(String(format: "%.2f", eventSpan))s < 0.5s minimum")
            activeSpeechEventStart = nil
            activeSpeechEventDBSum = 0
            activeSpeechEventDBCount = 0
            activeSpeechEventPeakDB = 0
            return
        }

        let event = SnoreEvent(
            timestamp: startTime,
            category: .sleepTalking,
            intensity: .quiet,
            averageDB: activeSpeechEventDBCount > 0 ? activeSpeechEventDBSum / Double(activeSpeechEventDBCount) : 0,
            peakDB: activeSpeechEventPeakDB,
            duration: eventSpan
        )
        event.session = session

        if session.events == nil {
            session.events = []
        }
        session.events?.append(event)
        eventsCount = session.events?.count ?? 0

        activeSpeechEventStart = nil
        activeSpeechEventDBSum = 0
        activeSpeechEventDBCount = 0
        activeSpeechEventPeakDB = 0
    }

    private func audioFileURL(for sessionID: UUID) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("session_\(sessionID.uuidString).caf")
    }

    private func eventFileURL(eventID: UUID, sessionID: UUID) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("event_\(eventID.uuidString)_session_\(sessionID.uuidString).caf")
    }

    /// Compresses a raw per-event .caf file to AAC .m4a.
    ///
    /// Encodes to mono 16 kHz / 24 kbps AAC rather than using
    /// `AVAssetExportPresetAppleM4A`, which offers no bitrate/sample-rate
    /// control and preserves the mic's native 44.1/48 kHz rate. Snore energy
    /// is almost entirely below ~1.5 kHz, so 16 kHz (8 kHz Nyquist) at a low
    /// bitrate keeps clips clearly recognizable while cutting file size 3–5×.
    /// The reader output settings force downmix + resample to mono 16 kHz PCM
    /// so the AAC encoder only has to compress.
    private func compressEventFile(from sourceURL: URL, to destinationURL: URL) async -> Bool {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        let asset = AVURLAsset(url: sourceURL)
        guard let track = try? await asset.loadTracks(withMediaType: .audio).first,
              let reader = try? AVAssetReader(asset: asset),
              let writer = try? AVAssetWriter(outputURL: destinationURL, fileType: .m4a)
        else { return false }

        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ])
        guard reader.canAdd(readerOutput) else { return false }
        reader.add(readerOutput)

        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 24_000,
        ])
        writerInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(writerInput) else { return false }
        writer.add(writerInput)

        guard reader.startReading(), writer.startWriting() else { return false }
        writer.startSession(atSourceTime: .zero)

        let queue = DispatchQueue(label: "com.sleepguard.aac-encode")
        return await withCheckedContinuation { continuation in
            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    guard let buffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            continuation.resume(
                                returning: writer.status == .completed && reader.status == .completed
                            )
                        }
                        return
                    }
                    writerInput.append(buffer)
                }
            }
        }
    }

    /// Calibrated thresholds + SoundAnalysis confidence gates for the full-band
    /// capture path. Low = noisier rooms / stricter filtering;
    /// Medium = typical quiet bedroom (default); High = very quiet rooms.
    ///
    /// loud/epic lowered by 5 dB (2026-06-01) because RMS over 23 ms buffers
    /// under-reports impulsive snoring peaks. Peak-dB classification now
    /// compensates, but the thresholds were still sitting above real captured
    /// levels for loud snoring at typical bedside distances.
    private func applyDetectionSensitivity() {
        let sensitivity = UserPreferences.shared.detectionSensitivity
        switch sensitivity {
        case .low:
            snoreDetector.quietThreshold = -45.0
            snoreDetector.lightThreshold = -35.0
            snoreDetector.loudThreshold = -15.0
            snoreDetector.epicThreshold = -5.0
            snoreDetector.confidenceGate = 0.45
            snoreDetector.highConfidenceGate = 0.65
            snoreDetector.quietFallbackGate = 0.55
        case .medium:
            snoreDetector.quietThreshold = -50.0
            snoreDetector.lightThreshold = -40.0
            snoreDetector.loudThreshold = -20.0
            snoreDetector.epicThreshold = -10.0
            snoreDetector.confidenceGate = 0.35
            snoreDetector.highConfidenceGate = 0.55
            snoreDetector.quietFallbackGate = 0.45
        case .high:
            snoreDetector.quietThreshold = -55.0
            snoreDetector.lightThreshold = -45.0
            snoreDetector.loudThreshold = -25.0
            snoreDetector.epicThreshold = -15.0
            snoreDetector.confidenceGate = 0.25
            snoreDetector.highConfidenceGate = 0.45
            snoreDetector.quietFallbackGate = 0.35
        }
    }

    /// Minimum snore-event duration. Sensitivity-dependent so isolated single
    /// snores (~1 s) are retained on Medium/High while Low still filters
    /// transient sounds. Ground-truthed against bedroom recordings.
    private var minEventDuration: TimeInterval {
        switch UserPreferences.shared.detectionSensitivity {
        case .low: return 2.0
        case .medium: return 1.0
        case .high: return 0.5
        }
    }

    private func intensity(from state: DetectionState) -> SnoreIntensity {
        switch state {
        case .quiet: return .quiet
        case .light: return .light
        case .loud: return .loud
        case .epic: return .epic
        case .none: return .quiet
        }
    }

    private func intensityRank(_ intensity: SnoreIntensity) -> Int {
        switch intensity {
        case .quiet: return 0
        case .light: return 1
        case .loud: return 2
        case .epic: return 3
        }
    }
}
