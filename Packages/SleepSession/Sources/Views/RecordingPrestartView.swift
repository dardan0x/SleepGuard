import AudioEngine
import DesignSystem
import Env
import SwiftUI

@MainActor
struct RecordingPrestartView: View {
    @Environment(Theme.self) private var theme
    @Environment(SessionManager.self) private var sessionManager
    @Environment(RouterPath.self) private var routerPath
    @Environment(UserPreferences.self) private var userPreferences
    private let audioRecorder = AudioRecorder.shared

    private let delayOptions = [0, 15, 30, 45, 60]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                iconSection
                    .padding(.top, 24)
                
                headlineSection
                    .padding(.top, 24)

                tipsSection
                    .padding(.top, 24)

                VStack(spacing: 12) {
                    delaySection

                    helperText
                }
                .padding(.top, 24)

                StartRecordingButton(height: 56) {
                    Task {
                        if !audioRecorder.hasPermission {
                            let granted = await audioRecorder.requestPermission()
                            guard granted else { return }
                        }
                        let delay = userPreferences.recordingDelayMinutes
                        if delay > 0 {
                            RecordingDelayManager.shared.startDelay(minutes: delay)
                        } else {
                            try? sessionManager.startSession()
                        }
                    }
                }
                .padding(.top, 10)

                Button {
                    routerPath.navigateBack()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(.top, -10)

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 24)
        }
        .background(theme.bgPrimary.ignoresSafeArea())
    }

    private var iconSection: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(theme.bgCard)
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "moon.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accent)
            )
    }

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text("Ready to track your sleep?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("We'll listen for snoring through the night. Audio stays on your device.")
                .font(.system(size: 16))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tipsSection: some View {
        VStack(spacing: 10) {
            tipRow(icon: "iphone", text: "Place your phone on the nightstand")
            tipRow(icon: "bolt.fill", text: "Keep it plugged in")
            tipRow(icon: "bell.slash.fill", text: "Silence notifications")
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(theme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusCard)
    }

    private var delaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start recording after")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            HStack(spacing: 8) {
                ForEach(delayOptions, id: \.self) { minutes in
                    delayButton(minutes: minutes)
                }
            }
        }
        .padding(16)
        .background(theme.bgCard)
        .cornerRadius(theme.radiusCard)
    }

    private func delayButton(minutes: Int) -> some View {
        let isSelected = userPreferences.recordingDelayMinutes == minutes
        let label = minutes == 0 ? "Off" : (minutes == 60 ? "1h" : "\(minutes)m")

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                userPreferences.recordingDelayMinutes = minutes
            }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? theme.accent : theme.bgElevated)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var helperText: some View {
        Text("Use this if you need time to fall asleep before recording begins.")
            .font(.system(size: 14))
            .foregroundStyle(theme.textTertiary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}
