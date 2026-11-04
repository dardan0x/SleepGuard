import AudioEngine
import DesignSystem
import Env
import Models
import SwiftUI
import UIKit

@MainActor
struct RecordingPrestartView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @Environment(RouterPath.self) private var routerPath
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(AppConfig.self) private var appConfig
  private let audioRecorder = AudioRecorder.shared

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
                  subtitle: Strings.snoreInterrupterLockscreenNote
                ) {
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
      }
    )
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
      return Strings.snoreInterrupterOffValueFormat
    case .always:
      return Strings.snoreInterrupterAlwaysValueFormat
    case .fiveSeconds:
      return Strings.snoreInterrupterFiveSecondsValueFormat
    case .fifteenSeconds:
      return Strings.snoreInterrupterFifteenSecondsValueFormat
    case .thirtySeconds:
      return Strings.snoreInterrupterThirtySecondsValueFormat
    case .sixtySeconds:
      return Strings.snoreInterrupterSixtySecondsValueFormat
    }
  }
}

enum PrestartPresentation {
  case snoreInterrupter
  case chargingAlert
  case microphoneAlert
}
