import AVFoundation
import DesignSystem
import Env
import SwiftUI
import UserNotifications

@MainActor
struct SettingsPermissionsSection: View {
  @Environment(Theme.self) private var theme
  @Environment(NotificationPermissionManager.self) private var notifications
  @State private var permissionStatus: AVAudioSession.RecordPermission = .undetermined

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionPermissions)
      VStack(spacing: 16) {
        Button {
          handleMicrophoneTap()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "mic.fill", color: theme.accent)
            Text(Strings.settingsMicrophoneAccess)
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            statusView
          }
        }
        .buttonStyle(.plain)
        .disabled(permissionStatus == .granted)

        Button {
          handleNotificationTap()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "bell.fill", color: theme.accent)
            Text(Strings.settingsNotificationsAccess)
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            notificationStatusView
          }
        }
        .buttonStyle(.plain)
        .disabled(isNotificationGranted)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
    .onAppear {
      checkPermission()
    }
    .task {
      await notifications.refreshStatus()
    }
  }

  // MARK: - Status

  @ViewBuilder
  private var statusView: some View {
    switch permissionStatus {
    case .granted:
      HStack(spacing: 4) {
        Circle()
          .fill(theme.scoreGreen)
          .frame(width: 6, height: 6)
        Text(Strings.settingsMicrophoneStatusGranted)
          .font(.system(size: 15))
          .foregroundStyle(theme.scoreGreen)
      }
    case .denied:
      HStack(spacing: 4) {
        Text(Strings.settingsMicrophoneStatusDenied)
          .font(.system(size: 15))
          .foregroundStyle(theme.destructive)
        Image(systemName: "chevron.right")
          .font(.system(size: 13))
          .foregroundStyle(theme.textTertiary)
      }
    case .undetermined:
      HStack(spacing: 4) {
        Text(Strings.settingsMicrophoneEnable)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.accent)
        Image(systemName: "chevron.right")
          .font(.system(size: 13))
          .foregroundStyle(theme.textTertiary)
      }
    @unknown default:
      EmptyView()
    }
  }

  // MARK: - Notification status

  private var isNotificationGranted: Bool {
    switch notifications.authorizationStatus {
    case .authorized, .provisional, .ephemeral: true
    default: false
    }
  }

  @ViewBuilder
  private var notificationStatusView: some View {
    switch notifications.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      HStack(spacing: 4) {
        Circle()
          .fill(theme.scoreGreen)
          .frame(width: 6, height: 6)
        Text(Strings.settingsMicrophoneStatusGranted)
          .font(.system(size: 15))
          .foregroundStyle(theme.scoreGreen)
      }
    case .denied:
      HStack(spacing: 4) {
        Text(Strings.settingsMicrophoneStatusDenied)
          .font(.system(size: 15))
          .foregroundStyle(theme.destructive)
        Image(systemName: "chevron.right")
          .font(.system(size: 13))
          .foregroundStyle(theme.textTertiary)
      }
    default:
      HStack(spacing: 4) {
        Text(Strings.settingsMicrophoneEnable)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.accent)
        Image(systemName: "chevron.right")
          .font(.system(size: 13))
          .foregroundStyle(theme.textTertiary)
      }
    }
  }

  // MARK: - Actions

  private func checkPermission() {
    permissionStatus = AVAudioSession.sharedInstance().recordPermission
  }

  private func handleNotificationTap() {
    switch notifications.authorizationStatus {
    case .notDetermined:
      Task { await notifications.requestAuthorization() }
    case .denied:
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    default:
      break
    }
  }

  private func handleMicrophoneTap() {
    switch permissionStatus {
    case .undetermined:
      Task {
        let granted = await withCheckedContinuation { continuation in
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
          }
        }
        permissionStatus = granted ? .granted : .denied
      }
    case .denied:
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    case .granted:
      break
    @unknown default:
      break
    }
  }
}
