import AudioEngine
import SwiftUI
import Env
import DesignSystem
import UIKit

@MainActor
struct RecordingCountdownView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Theme.self) private var theme
  @State private var showChargingAlert = false
  @State private var showMicrophoneAlert = false

  var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        VStack(spacing: 16) {
          Image(systemName: "moon.stars.fill")
            .font(.system(size: 56))
            .foregroundStyle(theme.accent)

          Text(Strings.sessionCountdownLabel)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(theme.textSecondary)

          Text(RecordingDelayManager.shared.remainingTimeString)
            .font(.system(size: 72, weight: .thin, design: .rounded))
            .foregroundStyle(theme.textPrimary)
            .monospacedDigit()
        }

        Spacer()

        VStack(spacing: 16) {
          Button {
            RecordingDelayManager.shared.cancel()
          } label: {
            Text(Strings.actionCancel)
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(theme.textPrimary)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.bgCard)
              .overlay(
                RoundedRectangle(cornerRadius: 100)
                  .stroke(theme.border, lineWidth: 1)
              )
              .clipShape(Capsule())
          }

          Button {
            Task {
              if !AudioRecorder.shared.hasPermission {
                let granted = await AudioRecorder.shared.requestPermission()
                guard granted else {
                  showMicrophoneAlert = true
                  return
                }
              }
              guard isCharging else {
                showChargingAlert = true
                return
              }
              startSession()
            }
          } label: {
            Text(Strings.actionStartNow)
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.accent)
              .clipShape(Capsule())
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .recordingDelayDidComplete)) { _ in
      try? sessionManager.startSession()
    }
    .alert(Strings.sessionChargingAlertTitle, isPresented: $showChargingAlert) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.sessionChargingAlertStartAnyway) {
        Task { @MainActor in
          startSession()
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

  private func startSession() {
    RecordingDelayManager.shared.cancel()
    do {
      try SessionManager.shared.startSession()
    } catch {
      print("Failed to start session: \(error)")
    }
  }

  private var isCharging: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    #endif
  }
}
