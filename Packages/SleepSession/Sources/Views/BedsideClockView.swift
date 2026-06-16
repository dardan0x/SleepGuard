import SwiftUI
import AudioEngine
import Env
import Models
import DesignSystem

@MainActor
struct BedsideClockView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AudioRecorder.self) private var audioRecorder
    @Environment(SoundAnalysisDetector.self) private var soundAnalysisDetector
    @Environment(SoothingMelodyPlayer.self) private var soothingMelodyPlayer
    @Environment(AppConfig.self) private var appConfig
    @Environment(Theme.self) private var theme
    
    @State private var currentTime = Date()
    @State private var showShortSessionAlert = false
    
    var body: some View {
        ZStack {
            theme.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    BedsideClockBadgesView(
                        eventsCount: sessionManager.eventsCount
                    )
                    
                    if isMelodyEnabled && !soothingMelodyPlayer.isMutedForSession {
                        melodyDisclaimer
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                BedsideClockClockView(
                    timeString: timeString,
                    dateString: dateString
                )
                
                Spacer()
                
                BedsideClockWaveformView(
                    durationString: durationString,
                    levels: simulatedWaveform
                )
                
                Spacer()
                
                
                BedsideClockStatusView(
                    statusLabel: statusLabel,
                    snoringColor: snoringColor
                )
                
                Spacer()
                
                    StopRecordingButton(height: 52) {
                        if let session = sessionManager.currentSession,
                           currentTime.timeIntervalSince(session.startDate) < SleepSession.minimumSaveDuration {
                            showShortSessionAlert = true
                        } else {
                            Task {
                                _ = await sessionManager.stopSession()
                            }
                        }
                    }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .overlay(alignment: .top) {
                if isMelodyEnabled && soothingMelodyPlayer.isPlaying {
                    melodyOverlay
                }
            }
            .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showShortSessionAlert) {
                Button(Strings.actionKeepRecording, role: .cancel) { }
                Button(Strings.actionStopAnyway) {
                    sessionManager.stopAndDiscardSession()
                }
            } message: {
                Text(String(format: Strings.sessionSummaryTooShortMessageFormat, Int(SleepSession.minimumSaveDuration / 60)))
            }
            
        }
        .task {
            while !Task.isCancelled {
                let now = Date()
                let newSecond = Calendar.current.component(.second, from: now)
                let oldSecond = Calendar.current.component(.second, from: currentTime)
                if newSecond != oldSecond {
                    currentTime = now
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var timeString: String {
        DateFormatters.time.string(from: currentTime)
    }
    
    private var dateString: String {
        DateFormatters.weekdayAndMonthDay.string(from: currentTime).uppercased()
    }
    
    private var durationString: String {
        guard let session = sessionManager.currentSession else { return "0 min" }
        let duration = currentTime.timeIntervalSince(session.startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%d h %d min", hours, minutes)
        }
        return String(format: "%d min", minutes)
    }
    
    private var simulatedWaveform: [Double] {
        let baseLevel = Double(max(0, (audioRecorder.currentDB + 60) / 40))
        return (0..<9).map { index in
            let variation = sin(Double(index) * 1.3 + Date().timeIntervalSince1970 * 5) * 0.3
            return max(0.1, min(1.0, baseLevel + variation))
        }
    }
    
    private var snoringColor: Color {
        switch sessionManager.currentDetectionState {
        case .none: return theme.textTertiary
        case .quiet: return theme.snoreQuiet
        case .light: return theme.snoreLight
        case .loud: return theme.snoreLoud
        case .epic: return theme.snoreEpic
        }
    }
    
    private var statusLabel: String {
        switch sessionManager.currentDetectionState {
        case .none: return Strings.statsCalendarIntensityQuiet
        case .quiet: return Strings.sessionBedsideSnoreQuiet
        case .light: return Strings.sessionBedsideSnoreLight
        case .loud: return Strings.sessionBedsideSnoreLoud
        case .epic: return Strings.sessionBedsideSnoreEpic
        }
    }
    
    private var isMelodyEnabled: Bool {
        appConfig.isEnabled(.soothingMelody) && UserPreferences.shared.soothingMelodyMode != .never
    }
    
    // MARK: - Melody Disclaimer
    
    private var melodyDisclaimer: some View {
        HStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.accent)
            
            Text(Strings.sessionBedsideMelodyEnabled)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            
            Text("·")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.textTertiary)
            
            Button {
                soothingMelodyPlayer.muteForSession()
            } label: {
                Text(Strings.muteForSession)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusSmall)
    }
    
    // MARK: - Melody Overlay
    
    private var melodyOverlay: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("\(Strings.playingSoothingMelodyPlayer) \(soothingMelodyPlayer.currentMelodyName ?? "Melody")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    soothingMelodyPlayer.muteForSession()
                } label: {
                    Text(Strings.muteForSession)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    soothingMelodyPlayer.stop()
                } label: {
                    Text(Strings.stopSoothingMelodyPlayer)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.accent, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
