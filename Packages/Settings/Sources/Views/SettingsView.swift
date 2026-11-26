import AVFoundation
import Config
import DesignSystem
import FactoryKit
import Health
import Models
import Platform
import Routing
import Services
import SwiftData
public import SwiftUI

/// Settings: the title row over the shared `SettingsContent`. This view owns
/// the values (preferences, permissions, feature flags) and what a tap does;
/// building them lives in `SettingsView+Values.swift`.
@MainActor
public struct SettingsView: View {
  @Environment(\.theme) private var theme
  @Injected(\.appConfig) var appConfig
  @Injected(\.userPreferences) var userPreferences
  @Injected(\.watchConnectivityManager) var watchConnectivityManager
  @Injected(\.healthKitSync) var healthKitSync
  @Injected(\.notificationPermissionManager) var notifications
  @Injected(\.storageLimitEnforcer) var storageLimitEnforcer
  @Environment(\.modelContext) var modelContext
  @Environment(\.openURL) var openURL
  @Environment(RouterPath.self) var routerPath

  @State var microphone: AVAudioSession.RecordPermission = .undetermined
  @State var showDeleteConfirmation = false
  @State var pendingStorageLimitMB: Int?
  @State var testReport: CleanupReport?
  #if DEBUG
  @State private var showDebugConfig = false
  #endif

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      titleRow
        .padding(.horizontal, 20)
        .padding(.top, 10)

      SettingsContent(
        permissions: permissions, recording: recording, profile: profile, watch: watch,
        storage: storage, data: data, about: about)
      {
        #if DEBUG
        Button("Debug Config") { showDebugConfig = true }
          .foregroundStyle(theme.palette.textSecondary)
        #endif
      }
    }
    .background(theme.palette.bgPrimary)
    .onAppear { microphone = AVAudioSession.sharedInstance().recordPermission }
    .task { await notifications.refreshStatus() }
    #if DEBUG
      .sheet(isPresented: $showDebugConfig) {
        NavigationStack { DebugConfigView() }
      }
    #endif
      .toolbar(.hidden, for: .navigationBar)
      .alert(Strings.settingsDeleteAll, isPresented: $showDeleteConfirmation) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.actionDeleteAll, role: .destructive) { deleteAllData() }
      } message: {
        Text(Strings.settingsDeleteAllConfirmMessage)
      }
      .alert(
        Strings.settingsLowerStorageLimitTitle,
        isPresented: Binding(get: { pendingStorageLimitMB != nil }, set: { if !$0 { pendingStorageLimitMB = nil } }))
    {
      Button(Strings.actionCancel, role: .cancel) { pendingStorageLimitMB = nil }
      Button(Strings.actionDelete, role: .destructive) { confirmLowerStorageLimit() }
    } message: {
      Text(Strings.settingsLowerStorageLimitMessage)
    }
    .alert(
      Strings.settingsTestCleanup,
      isPresented: Binding(get: { testReport != nil }, set: { if !$0 { testReport = nil } }),
      presenting: testReport)
    { _ in
      Button(Strings.actionOk) {}
    } message: { report in
      Text(String(
        format: Strings.settingsTestCleanupResultFormat, report.filesRemoved, report.bytesRemoved / 1_024 / 1_024,
        report.sessionsAffected, report.dayLimitSessions, report.sizeLimitSessions))
    }
  }

  // MARK: - Title

  private var titleRow: some View {
    HStack {
      Text(Strings.tabSettings)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
      Spacer()
      ZStack {
        RoundedRectangle(cornerRadius: 15)
          .fill(theme.palette.accent)
          .frame(width: 30, height: 30)
        Image(systemName: "gearshape.fill")
          .font(.system(size: 16))
          .foregroundStyle(.white)
      }
      .accessibilityHidden(true)
    }
  }
}

// MARK: - Display Helpers

extension UserPreferences.AppearanceSetting {
  var displayName: String {
    switch self {
    case .light: Strings.settingsThemeLight
    case .dark: Strings.settingsThemeDark
    case .system: Strings.settingsThemeSystem
    }
  }
}

#Preview {
  SettingsView()
}
