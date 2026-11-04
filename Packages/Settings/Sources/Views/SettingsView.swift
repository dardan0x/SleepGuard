import DesignSystem
import Env
import Models
import Personalization
import SwiftData
import SwiftUI

@MainActor
public struct SettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(AppConfig.self) private var appConfig
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(WatchConnectivityManager.self) private var watchConnectivityManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL
  @Environment(RouterPath.self) private var routerPath

  @State private var showDeleteConfirmation = false
  @State private var showThemePicker = false
  #if DEBUG
  @State private var showDebugConfig = false
  #endif

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      titleRow
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: 24) {
          SettingsPermissionsSection()
          SettingsRecordingSection()
          SettingsAppearanceSection()
          SettingsProfileSection(onTapProfile: { routerPath.presentedSheet = .profileEditor })
          if appConfig.isEnabled(.watchApp) {
            SettingsWatchSection()
          }
          SettingsStorageSection()
          SettingsDataSection(onShowDeleteConfirmation: { showDeleteConfirmation = true })
          SettingsAboutSection(onRateApp: rateApp)
          #if DEBUG
          Button("Debug Config") { showDebugConfig = true }
            .foregroundStyle(theme.textSecondary)
          #endif
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
      }
    }
    .background(theme.bgPrimary)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
    #endif
    #if DEBUG
      .sheet(isPresented: $showDebugConfig) {
        NavigationStack { DebugConfigView() }
          .environment(AppConfig.shared)
          .environment(Theme.shared)
      }
    #endif
      .toolbar(.hidden, for: .navigationBar)
      .alert(Strings.settingsDeleteAll, isPresented: $showDeleteConfirmation) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.actionDeleteAll, role: .destructive) {
          deleteAllData()
        }
      } message: {
        Text(Strings.settingsDeleteAllConfirmMessage)
      }
  }

  // MARK: - Title

  private var titleRow: some View {
    HStack {
      Text(Strings.tabSettings)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.textPrimary)
      Spacer()
      ZStack {
        RoundedRectangle(cornerRadius: 15)
          .fill(theme.accent)
          .frame(width: 30, height: 30)
        Image(systemName: "gearshape.fill")
          .font(.system(size: 16))
          .foregroundStyle(.white)
      }
    }
  }

  // MARK: - Actions

  private func deleteAllData() {
    do {
      // Delete all events first with an intermediate save so they are fully
      // removed from the context before session deletion. This prevents the
      // SwiftData faulting crash that happens when cascade-delete tries to
      // resolve lazy attributes on faulted relationship objects.
      let allEvents = try modelContext.fetch(FetchDescriptor<SnoreEvent>())
      for event in allEvents {
        modelContext.delete(event)
      }
      if !allEvents.isEmpty {
        try modelContext.save()
      }

      let sessions = try modelContext.fetch(FetchDescriptor<SleepSession>())
      for session in sessions {
        // Resolve transformable faults before deletion to prevent
        // "detached from a context without resolving attribute faults" crash.
        _ = session.sleepStageSegments
        _ = session.recordingGaps
        deleteSessionFiles(session)
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      // Silent failure — no toast infrastructure in this app
    }
  }

  private func rateApp() {
    guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id0?action=write-review") else { return }
    openURL(writeReviewURL)
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
    .environment(Theme.shared)
    .environment(UserPreferences.shared)
    .environment(WatchConnectivityManager.shared)
    .environment(HealthKitSync.shared)
}
