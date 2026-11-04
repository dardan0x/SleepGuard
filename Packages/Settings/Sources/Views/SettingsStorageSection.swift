import DesignSystem
import Env
import SwiftData
import SwiftUI

@MainActor
struct SettingsStorageSection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.modelContext) private var modelContext

  private let mbOptions = [100, 250, 500, 1000, 2000]
  private let dayOptions = [7, 14, 30, 60, 90]

  @State private var testReport: CleanupReport?
  @State private var showTestAlert = false
  @State private var pendingStorageLimitMB: Int?
  @State private var showLowerLimitConfirmation = false

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      SettingsSectionTitle(text: Strings.settingsSectionStorage)
      VStack(spacing: 16) {
        storageLimitRow
        if userPreferences.limitStorageEnabled {
          storageLimitPicker
        }
        dayLimitRow
        if userPreferences.limitDaysEnabled {
          dayLimitPicker
        }

        #if DEBUG
        Button {
          runTestCleanup()
        } label: {
          HStack(spacing: 10) {
            SettingsIconBackground(systemName: "testtube.2", color: theme.accent)
            Text(Strings.settingsTestCleanup)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(theme.accent)
            Spacer()
          }
        }
        .buttonStyle(.plain)
        #endif
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
    .alert(Strings.settingsTestCleanup, isPresented: $showTestAlert, presenting: testReport) { _ in
      Button(Strings.actionOk) {}
    } message: { report in
      Text(String(format: Strings.settingsTestCleanupResultFormat, report.filesRemoved, report.bytesRemoved / 1_024 / 1_024, report.sessionsAffected, report.dayLimitSessions, report.sizeLimitSessions))
    }
    .alert(Strings.settingsLowerStorageLimitTitle, isPresented: $showLowerLimitConfirmation) {
      Button(Strings.actionCancel, role: .cancel) {
        pendingStorageLimitMB = nil
      }
      Button(Strings.actionDelete, role: .destructive) {
        if let pending = pendingStorageLimitMB {
          userPreferences.storageLimitMB = pending
          pendingStorageLimitMB = nil
          runCleanup()
        }
      }
    } message: {
      Text(Strings.settingsLowerStorageLimitMessage)
    }
  }

  private func handleStorageLimitChange(newValue: Int) {
    guard newValue < userPreferences.storageLimitMB else {
      userPreferences.storageLimitMB = newValue
      return
    }
    pendingStorageLimitMB = newValue
    showLowerLimitConfirmation = true
  }

  private func runCleanup() {
    Task {
      _ = await StorageLimitEnforcer.shared.enforceLimits(modelContext: modelContext)
    }
  }

  #if DEBUG
  private func runTestCleanup() {
    Task {
      let injected = StorageLimitEnforcer.shared.injectDummyAudioForTesting(modelContext: modelContext)
      if injected == 0 {
        MockDataGenerator.generate(modelContext: modelContext)
        _ = StorageLimitEnforcer.shared.injectDummyAudioForTesting(modelContext: modelContext)
      }
      testReport = await StorageLimitEnforcer.shared.enforceLimits(modelContext: modelContext)
      showTestAlert = true
    }
  }
  #endif

  // MARK: - Storage Limit

  private var storageLimitRow: some View {
    HStack(spacing: 10) {
      SettingsIconBackground(systemName: "externaldrive.fill", color: theme.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text(Strings.settingsLimitStorage)
          .font(.system(size: 15))
          .foregroundStyle(theme.textPrimary)
        Text(Strings.settingsLimitStorageDescription)
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
          .lineLimit(2)
      }
      Spacer()
      Toggle("", isOn: Binding(
        get: { userPreferences.limitStorageEnabled },
        set: { userPreferences.limitStorageEnabled = $0 }
      ))
      .labelsHidden()
      .tint(theme.scoreGreen)
    }
  }

  private var storageLimitPicker: some View {
    HStack(spacing: 10) {
      SettingsIconBackground(systemName: "gauge.with.dots.needle.67percent", color: theme.textTertiary)
      Text(Strings.settingsStorageLimitMb)
        .font(.system(size: 15))
        .foregroundStyle(theme.textPrimary)
      Spacer()
      Picker("", selection: Binding(
        get: { userPreferences.storageLimitMB },
        set: { handleStorageLimitChange(newValue: $0) }
      )) {
        ForEach(mbOptions, id: \.self) { mb in
          Text("\(mb) \(Strings.settingsUnitMb)")
            .tag(mb)
        }
      }
      .pickerStyle(.menu)
      .tint(theme.accent)
    }
  }

  // MARK: - Day Limit

  private var dayLimitRow: some View {
    HStack(spacing: 10) {
      SettingsIconBackground(systemName: "calendar.badge.clock", color: theme.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text(Strings.settingsLimitDays)
          .font(.system(size: 15))
          .foregroundStyle(theme.textPrimary)
        Text(Strings.settingsLimitDaysDescription)
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
          .lineLimit(2)
      }
      Spacer()
      Toggle("", isOn: Binding(
        get: { userPreferences.limitDaysEnabled },
        set: { userPreferences.limitDaysEnabled = $0 }
      ))
      .labelsHidden()
      .tint(theme.scoreGreen)
    }
  }

  private var dayLimitPicker: some View {
    HStack(spacing: 10) {
      SettingsIconBackground(systemName: "clock.arrow.circlepath", color: theme.textTertiary)
      Text(Strings.settingsMaxDays)
        .font(.system(size: 15))
        .foregroundStyle(theme.textPrimary)
      Spacer()
      Picker("", selection: Binding(
        get: { userPreferences.maxDays },
        set: { userPreferences.maxDays = $0 }
      )) {
        ForEach(dayOptions, id: \.self) { days in
          Text("\(days) \(Strings.settingsUnitDays)")
            .tag(days)
        }
      }
      .pickerStyle(.menu)
      .tint(theme.accent)
    }
  }
}
