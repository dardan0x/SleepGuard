import AudioEngine
import DesignSystem
import Env
import SwiftUI
import UIKit

@MainActor
struct RecordingPrestartView: View {
    @Environment(Theme.self) private var theme
    @Environment(SessionManager.self) private var sessionManager
    @Environment(RouterPath.self) private var routerPath
    @Environment(UserPreferences.self) private var userPreferences
    private let audioRecorder = AudioRecorder.shared

    private let delayOptions = [0, 15, 30, 45, 60]
    @State private var showSoothingMelodySheet = false
    @State private var showChargingAlert = false
    @State private var showMicrophoneAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                iconSection
                    .padding(.top, 24)
                
                headlineSection
                    .padding(.top, 14)

                tipsSection
                    .padding(.top, 12)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        delaySection
                        soothingMelodyRow(
                            icon: "timer",
                            title: Strings.soothingMelodyRecordingPrestartViewTitle,
                            value: soothingMelodyValue,
                            subtitle: userPreferences.soothingMelodyMode != .never ? Strings.soothingMelodyLockscreenNote : nil
                        ) {
                            showSoothingMelodySheet = true
                        }
                        .padding(.top, 8)
                    }
                    helperText
                }
                .padding(.top, 24)

                StartRecordingButton(height: 56) {
                    Task { @MainActor in
                        if !audioRecorder.hasPermission {
                            let granted = await audioRecorder.requestPermission()
                            guard granted else {
                                showMicrophoneAlert = true
                                return
                            }
                        }
                        guard isCharging else {
                            showChargingAlert = true
                            return
                        }
                        beginSession()
                    }
                }
//                .padding(.top, 10)

                Button {
                    routerPath.navigateBack()
                } label: {
                    Text(Strings.actionCancel)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(.top, -10)

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 24)
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .sheet(isPresented: $showSoothingMelodySheet) {
            SoothingMelodySheet()
        }
        .alert(Strings.sessionChargingAlertTitle, isPresented: $showChargingAlert) {
            Button(Strings.actionCancel, role: .cancel) {}
            Button(Strings.sessionChargingAlertStartAnyway) {
                Task { @MainActor in
                    beginSession()
                }
            }
        } message: {
            Text(Strings.sessionChargingAlertMessage)
        }
        .alert(Strings.sessionMicrophoneAlertTitle, isPresented: $showMicrophoneAlert) {
            Button(Strings.actionCancel, role: .cancel) {}
            Button(Strings.sessionMicrophoneAlertOpenSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(Strings.sessionMicrophoneAlertMessage)
        }
    }

    private func beginSession() {
        let delay = UserPreferences.shared.recordingDelayMinutes
        if delay > 0 {
            RecordingDelayManager.shared.startDelay(minutes: delay)
        } else {
            do {
                try SessionManager.shared.startSession()
            } catch {
                print("Failed to start session: \(error)")
            }
        }
    }

    private var isCharging: Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }

    private var soothingMelodyValue: String {
        switch userPreferences.soothingMelodyMode {
        case .never:
            return Strings.offSoothingMelodyValueFormat
        case .always:
            return Strings.alwaysSoothingMelodyValueFormat
        case .fiveSeconds:
            return Strings.fiveSecondsSoothingMelodyValueFormat
        case .fifteenSeconds:
            return Strings.fifteenSecondsSoothingMelodyValueFormat
        case .thirtySeconds:
            return Strings.thirtySecondsSoothingMelodyValueFormat
        case .sixtySeconds:
            return Strings.sixtySecondsSoothingMelodyValueFormat
        }
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
            Text(Strings.statsEmptyTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(Strings.sessionPrestartBody)
                .font(.system(size: 16))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tipsSection: some View {
        ZStack {
            // Outer soft glow
            RoundedRectangle(cornerRadius: theme.radiusCard)
                .fill(Color(hex: "#FF453A").opacity(0.12))
                .blur(radius: 12)
                .offset(y: 4)
                .padding(.horizontal, -4)

            // Inner concentrated glow
            RoundedRectangle(cornerRadius: theme.radiusCard)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FF453A").opacity(0.25), Color(hex: "#FF453A").opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 8)
                .offset(y: 6)
                .padding(.horizontal, -2)

            VStack(spacing: 0) {
                tipRow(icon: "iphone", text: Strings.sessionPrestartTipPhone)
                Divider()
                    .background(theme.border)
                    .padding(.leading, 52)
                tipRow(icon: "bolt.fill", text: Strings.sessionPrestartTipPluggedIn)
            }
            .background(
                ZStack {
                    theme.bgCard
                    RoundedRectangle(cornerRadius: theme.radiusCard)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#FF453A").opacity(0.6), Color(hex: "#FF453A").opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .cornerRadius(theme.radiusCard)
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
    }

    private func soothingMelodyRow(icon: String, title: String, value: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.accent)
                        .frame(width: 24)

                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Text(value)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }

                if let subtitle {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 12))
                        Text(subtitle)
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .foregroundStyle(theme.textTertiary)
                    .padding(.top, 4)
                    .padding(.leading, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, subtitle == nil ? 14 : 12)
            .background(theme.bgCard)
            .cornerRadius(theme.radiusCard)
        }
        .buttonStyle(.plain)
    }

    private var delaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.sessionPrestartDelayLabel)
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
        let label = minutes == 0 ? Strings.sessionPrestartDelayOff : (minutes == 60 ? "1h" : "\(minutes)m")

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
        Text(Strings.soothingMelodyRowHelperText)
            .font(.system(size: 14))
            .foregroundStyle(theme.textTertiary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}
