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
  @Injected(\.theme) private var theme
  @Injected(\.sessionManager) private var sessionManager
  @Environment(RouterPath.self) private var routerPath
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.appConfig) private var appConfig
  @Injected(\.audioRecorder) private var audioRecorder
  @Injected(\.recordingDelayManager) private var recordingDelayManager

  @State private var activePresentation: PrestartPresentation?

  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack(spacing: 0) {
          PrestartHeaderView()
            .padding(.top, DeviceSize.isCompactHeight ? 20 : 24)

          PrestartTipsSection()
            .padding(.top, DeviceSize.isCompactHeight ? 20 : 24)

          VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
              PrestartDelaySection()
              if appConfig.isEnabled(.snoreInterrupter) {
                PrestartSnoreInterrupterRow(
                  icon: "timer",
                  title: Strings.snoreInterrupterRecordingPrestartViewTitle,
                  value: snoreInterrupterValue,
                  subtitle: Strings.snoreInterrupterLockscreenNote)
                {
                  activePresentation = .snoreInterrupter
                }
                .padding(.top, 8)
              }
            }
            if appConfig.isEnabled(.snoreInterrupter) {
              Text(Strings.snoreInterrupterRowHelperText)
                .font(.system(size: 14))
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            }
          }
          .padding(.top, DeviceSize.isCompactHeight ? 20 : 24)

          Color.clear.frame(height: 160)
        }
        .padding(.horizontal, 24)
      }

      VStack(spacing: 0) {
        StartRecordingButton(height: 56) {
          Task { @MainActor in
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
        }

        Button {
          routerPath.navigateBack()
        } label: {
          Text(Strings.actionCancel)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
      }
      .padding(.horizontal, 24)
      .background(theme.bgPrimary.ignoresSafeArea(edges: .bottom))
    }
    .background(theme.bgPrimary.ignoresSafeArea())
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
