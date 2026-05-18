import SwiftUI
import SwiftData
import Env
import DesignSystem
import Models

@MainActor
public struct SettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(WatchConnectivityManager.self) private var watchConnectivityManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL

  @State private var showDeleteConfirmation = false
  @State private var showThemePicker = false

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      titleRow
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: 24) {
          SettingsPermissionsSection()
          SettingsAppearanceSection()
          SettingsWatchSection()
          SettingsDataSection(onShowDeleteConfirmation: { showDeleteConfirmation = true })
          SettingsAboutSection(onRateApp: rateApp)
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
        .font(.system(size: 28, weight: .bold))
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
      let sessionsDescriptor = FetchDescriptor<SleepSession>()
      let sessions = try modelContext.fetch(sessionsDescriptor)
      for session in sessions {
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
