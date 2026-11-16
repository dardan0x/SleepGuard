import AudioEngine
import DesignSystem
import Env
import FactoryKit
import Models
import Routing
import SwiftUI
import UIKit

@MainActor
struct RecordingPrestartView: View {
  @Injected(\.sessionManager) private var sessionManager
  @Environment(RouterPath.self) private var routerPath
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.appConfig) private var appConfig
  @Injected(\.audioRecorder) private var audioRecorder
  @Injected(\.recordingDelayManager) private var recordingDelayManager

  @State private var activePresentation: PrestartPresentation?

  var body: some View {
    // The shared prestart content (ADR 0006); the start delay and the Snore
    // Interrupter rows go in its options slot.
    PrestartContent(
      compact: DeviceSize.isCompactHeight,
      onStart: { Task { await startTapped() } },
      onCancel: { routerPath.navigateBack() })
    {
      PrestartOptions(
        showsSnoreInterrupter: appConfig.isEnabled(.snoreInterrupter),
        snoreInterrupterValue: snoreInterrupterValue)
      {
        activePresentation = .snoreInterrupter
      }
    }
    .sheet(isPresented: isPresented(.snoreInterrupter)) {
      SnoreInterrupterSheet()
    }
    .alert(Strings.sessionChargingAlertTitle, isPresented: isPresented(.chargingAlert)) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.sessionChargingAlertStartAnyway) {
        Task { @MainActor in
          beginSession()
        }
      }
    } message: {
      Text(Strings.sessionChargingAlertMessage)
    }
    .alert(Strings.sessionMicrophoneAlertTitle, isPresented: isPresented(.microphoneAlert)) {
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

  /// Binding for the alert/sheet modifiers, derived from the enum state so
  /// the presentation machinery stays in one place (the modifier forms, and
  /// therefore their rendering, are unchanged).
  private func isPresented(_ presentation: PrestartPresentation) -> Binding<Bool> {
    Binding(
      get: { activePresentation == presentation },
      set: { isActive in
        if !isActive {
          activePresentation = nil
        }
      })
  }

  /// Microphone, then charger, then the session (or its delay).
  private func startTapped() async {
    if !audioRecorder.hasPermission {
      let granted = await audioRecorder.requestPermission()
      guard granted else {
        activePresentation = .microphoneAlert
        return
      }
    }
    guard isCharging else {
      activePresentation = .chargingAlert
      return
    }
    beginSession()
  }

  private func beginSession() {
    let delay = userPreferences.recordingDelayMinutes
    if delay > 0 {
      recordingDelayManager.startDelay(minutes: delay)
    } else {
      do {
        try sessionManager.startSession()
      } catch {
        Log.session.error("Failed to start session: \(String(describing: error), privacy: .public)")
        activePresentation = .startFailed
      }
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

  private var snoreInterrupterValue: String {
    switch userPreferences.snoreInterrupterMode {
    case .never:
      Strings.snoreInterrupterOffValueFormat
    case .always:
      Strings.snoreInterrupterAlwaysValueFormat
    case .fiveSeconds:
      Strings.snoreInterrupterFiveSecondsValueFormat
    case .fifteenSeconds:
      Strings.snoreInterrupterFifteenSecondsValueFormat
    case .thirtySeconds:
      Strings.snoreInterrupterThirtySecondsValueFormat
    case .sixtySeconds:
      Strings.snoreInterrupterSixtySecondsValueFormat
    }
  }
}

enum PrestartPresentation {
  case snoreInterrupter
  case chargingAlert
  case microphoneAlert
  case startFailed
}
