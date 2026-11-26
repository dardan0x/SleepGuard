import AudioEngine
import DesignSystem
import FactoryKit
import Models
import Services
import SwiftUI
import UIKit

@MainActor
struct RecordingCountdownView: View {
  @Injected(\.sessionManager) private var sessionManager
  @Injected(\.recordingDelayManager) private var recordingDelayManager
  @Injected(\.audioRecorder) private var audioRecorder
  @State private var activeAlert: CountdownAlert?

  var body: some View {
    RecordingCountdownContent(
      seconds: recordingDelayManager.currentRemainingSeconds,
      onCancel: { recordingDelayManager.cancel() },
      onStartNow: startNow)
      .onAppear {
        UIApplication.shared.isIdleTimerDisabled = true
      }
      .onDisappear {
        UIApplication.shared.isIdleTimerDisabled = sessionManager.isRecording
      }
      .onReceive(NotificationCenter.default.publisher(for: .recordingDelayDidComplete)) { _ in
        do {
          try sessionManager.startSession()
        } catch {
          Log.session.error("Delayed start failed: \(String(describing: error), privacy: .public)")
          activeAlert = .startFailed
        }
      }
      .alert(Strings.sessionChargingAlertTitle, isPresented: isPresented(.charging)) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.sessionChargingAlertStartAnyway) {
          Task { @MainActor in
            startSession()
          }
        }
      } message: {
        Text(Strings.sessionChargingAlertMessage)
      }
      .alert(Strings.sessionMicrophoneAlertTitle, isPresented: isPresented(.microphone)) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.sessionMicrophoneAlertOpenSettings) {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }
      } message: {
        Text(Strings.sessionMicrophoneAlertMessage)
      }
      .alert(Strings.sessionStartFailedAlertTitle, isPresented: isPresented(.startFailed)) {
        Button(Strings.actionOk, role: .cancel) {}
      } message: {
        Text(Strings.sessionStartFailedAlertMessage)
      }
  }

  /// Binding for the alert modifiers, derived from the enum state so the
  /// modifier forms (and their rendering) are unchanged.
  private func isPresented(_ alert: CountdownAlert) -> Binding<Bool> {
    Binding(
      get: { activeAlert == alert },
      set: { isActive in
        if !isActive {
          activeAlert = nil
        }
      })
  }

  /// Start now: the same microphone and charger checks as the prestart.
  private func startNow() {
    Task {
      if !audioRecorder.hasPermission {
        let granted = await audioRecorder.requestPermission()
        guard granted else {
          activeAlert = .microphone
          return
        }
      }
      guard isCharging else {
        activeAlert = .charging
        return
      }
      startSession()
    }
  }

  private func startSession() {
    recordingDelayManager.cancel()
    do {
      try sessionManager.startSession()
    } catch {
      Log.session.error("Failed to start session: \(String(describing: error), privacy: .public)")
      activeAlert = .startFailed
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

enum CountdownAlert {
  case charging
  case microphone
  case startFailed
}
